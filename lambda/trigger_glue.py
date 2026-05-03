import json
import logging
import os
from datetime import datetime, timezone
from urllib.parse import unquote_plus

import boto3
from botocore.exceptions import ClientError

LOGGER = logging.getLogger()
LOGGER.setLevel(os.getenv("LOG_LEVEL", "INFO"))

GLUE = boto3.client("glue")

def extract_s3_location(event):
    detail = event.get("detail", {})
    bucket_name = detail.get("bucket", {}).get("name")
    object_key = detail.get("object", {}).get("key")

    if not bucket_name or not object_key:
        raise ValueError("EventBridge event does not contain a valid S3 bucket and key")

    return bucket_name, unquote_plus(object_key)

def lambda_handler(event, context):
    LOGGER.info("Received event: %s", json.dumps(event))

    try:
        bucket_name, object_key = extract_s3_location(event)
        if not object_key.lower().endswith(".csv"):
            LOGGER.info("Ignoring non-CSV object: s3://%s/%s", bucket_name, object_key)
            return {
                "status": "ignored",
                "reason": "non_csv_object",
                "bucket": bucket_name,
                "key": object_key,
            }

        glue_job_name = os.environ["GLUE_JOB_NAME"]
        input_path = f"s3://{bucket_name}/{object_key}"
        event_time = event.get("time", datetime.now(timezone.utc).isoformat())

        # Add the missing required arguments
        arguments = {
            "--input_path": input_path,
            "--source_bucket": bucket_name,
            "--source_key": object_key,
            "--event_time": event_time,
            "--database_name": os.environ.get("DATABASE_NAME", "default_database"),
            "--table_name": os.environ.get("TABLE_NAME", "default_table"),
            "--warehouse_path": os.environ.get("WAREHOUSE_PATH", f"s3://{bucket_name}/warehouse/"),
        }

        LOGGER.info("Starting Glue job %s with arguments: %s", glue_job_name, arguments)

        response = GLUE.start_job_run(
            JobName=glue_job_name,
            Arguments=arguments,
        )

        job_run_id = response["JobRunId"]
        LOGGER.info("Started Glue job %s with run id %s", glue_job_name, job_run_id)

        return {
            "status": "started",
            "glue_job_name": glue_job_name,
            "job_run_id": job_run_id,
            "input_path": input_path,
        }

    except ClientError as e:
        LOGGER.error("AWS API error: %s", e)
        raise
    except Exception as e:
        LOGGER.error("Unexpected error: %s", e)
        raise
