locals {
  warehouse_path = "s3://${var.warehouse_bucket_name}/warehouse/"
  script_key     = "artifacts/glue/csv_to_iceberg.py"
  spark_conf = join(", ", [
    "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions",
    "spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog",
    "spark.sql.catalog.glue_catalog.warehouse=${local.warehouse_path}",
    "spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog",
    "spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO",
    "spark.sql.defaultCatalog=glue_catalog"
  ])
}

resource "aws_glue_catalog_database" "this" {
  name        = var.database_name
  description = "Iceberg database for the ${var.job_name} ingestion pipeline."
}

resource "aws_s3_object" "script" {
  bucket       = var.warehouse_bucket_name
  key          = local.script_key
  source       = var.script_local_path
  etag         = filemd5(var.script_local_path)
  content_type = "text/x-python"
}

resource "aws_glue_job" "this" {
  name     = var.job_name
  role_arn = var.role_arn

  glue_version      = var.glue_version
  number_of_workers = var.number_of_workers
  worker_type       = var.worker_type
  timeout           = var.timeout_minutes
  max_retries       = var.max_retries

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${var.warehouse_bucket_name}/${aws_s3_object.script.key}"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--job-language"                     = "python"
    "--enable-glue-datacatalog"          = "true"
    "--enable-metrics"                   = "true"
    "--enable-observability-metrics"     = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--continuous-log-logGroup"          = var.cloudwatch_log_group_name
    "--datalake-formats"                 = "iceberg"
    "--TempDir"                          = "s3://${var.warehouse_bucket_name}/temporary/"
    "--spark-event-logs-path"            = "s3://${var.warehouse_bucket_name}/sparkHistoryLogs/"
    "--database_name"                    = var.database_name
    "--table_name"                       = var.table_name
    "--warehouse_path"                   = local.warehouse_path
    "--conf"                             = local.spark_conf
  }

  tags = var.tags

  depends_on = [aws_glue_catalog_database.this]
}
