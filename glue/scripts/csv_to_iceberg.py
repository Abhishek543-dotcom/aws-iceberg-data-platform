import re
import sys
from typing import List

import boto3
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import DataFrame, functions as F


def normalize_columns(df: DataFrame) -> DataFrame:
    normalized_columns = []
    seen_names = {}

    for original_name in df.columns:
        normalized_name = re.sub(r"[^0-9a-zA-Z]+", "_", original_name.strip().lower()).strip("_")
        if not normalized_name:
            normalized_name = "column"

        next_index = seen_names.get(normalized_name, 0)
        seen_names[normalized_name] = next_index + 1
        final_name = normalized_name if next_index == 0 else f"{normalized_name}_{next_index}"
        normalized_columns.append(final_name)

    normalized_df = df
    for current_name, target_name in zip(df.columns, normalized_columns):
        if current_name != target_name:
            normalized_df = normalized_df.withColumnRenamed(current_name, target_name)

    return normalized_df


def table_exists(glue_client, database_name: str, table_name: str) -> bool:
    try:
        glue_client.get_table(DatabaseName=database_name, Name=table_name)
        return True
    except glue_client.exceptions.EntityNotFoundException:
        return False


def append_with_schema_evolution(spark, df: DataFrame, table_identifier: str) -> None:
    existing_schema = spark.table(table_identifier).schema
    existing_types = {field.name: field.dataType for field in existing_schema.fields}

    for field in df.schema.fields:
        if field.name in existing_types and field.dataType != existing_types[field.name]:
            df = df.withColumn(field.name, F.col(field.name).cast(existing_types[field.name]))

    new_fields = [field for field in df.schema.fields if field.name not in existing_types]
    if new_fields:
        additions = ", ".join(
            f"`{field.name}` {field.dataType.simpleString()}" for field in new_fields
        )
        spark.sql(f"ALTER TABLE {table_identifier} ADD COLUMNS ({additions})")

    refreshed_schema = spark.table(table_identifier).schema

    for field in refreshed_schema.fields:
        if field.name not in df.columns:
            df = df.withColumn(field.name, F.lit(None).cast(field.dataType))

    ordered_columns: List[str] = [field.name for field in refreshed_schema.fields]
    df.select(*ordered_columns).writeTo(table_identifier).append()


def main() -> None:
    args = getResolvedOptions(
        sys.argv,
        [
            "JOB_NAME",
            "input_path",
            "source_bucket",
            "source_key",
            "event_time",
            "database_name",
            "table_name",
            "warehouse_path",
        ],
    )

    spark_context = SparkContext()
    glue_context = GlueContext(spark_context)
    spark = glue_context.spark_session
    logger = glue_context.get_logger()

    job = Job(glue_context)
    job.init(args["JOB_NAME"], args)

    glue_client = boto3.client("glue")
    table_identifier = f"glue_catalog.{args['database_name']}.{args['table_name']}"

    raw_df = (
        spark.read.option("header", "true")
        .option("inferSchema", "true")
        .option("mode", "FAILFAST")
        .csv(args["input_path"])
    )

    row_count = raw_df.count()
    logger.info("Read %s records from %s", row_count, args["input_path"])

    df = normalize_columns(raw_df)
    df = (
        df.withColumn("source_bucket", F.lit(args["source_bucket"]))
        .withColumn("source_key", F.lit(args["source_key"]))
        .withColumn("pipeline_event_time", F.to_timestamp(F.lit(args["event_time"])))
        .withColumn("ingested_at", F.current_timestamp())
        .withColumn("event_date", F.to_date(F.col("ingested_at")))
    )

    if not table_exists(glue_client, args["database_name"], args["table_name"]):
        writer = (
            df.writeTo(table_identifier)
            .using("iceberg")
            .tableProperty("format-version", "2")
            .tableProperty("write.spark.accept-any-schema", "true")
            .partitionedBy("event_date")
        )
        writer.createOrReplace()
        logger.info("Created Iceberg table %s", table_identifier)
    else:
        append_with_schema_evolution(spark, df, table_identifier)
        logger.info("Appended data into Iceberg table %s", table_identifier)

    job.commit()


if __name__ == "__main__":
    main()
