# AWS Iceberg Data Platform

This repository provisions an event-driven lakehouse pipeline on AWS with Terraform. When a CSV file lands in S3, EventBridge forwards the object creation event to Lambda, Lambda starts a Glue 4.0 Spark job, and the Glue job writes the data into an Apache Iceberg table backed by Amazon S3 and the AWS Glue Data Catalog. Athena queries the Iceberg table, CloudWatch captures logs and metrics, and SNS sends operational alerts.

## Architecture

S3 input bucket -> EventBridge rule -> Lambda trigger -> AWS Glue ETL -> Apache Iceberg table in S3 + Glue Catalog -> Athena workgroup -> CloudWatch logs and alarms -> SNS email notification

## Repository Layout

```text
aws-iceberg-data-platform/
├── environments/dev/
│   ├── backend.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── variables.tf
├── modules/
│   ├── athena/
│   ├── cloudwatch/
│   ├── eventbridge/
│   ├── glue/
│   ├── iam/
│   ├── lambda/
│   ├── s3/
│   └── sns/
├── glue/scripts/csv_to_iceberg.py
├── infra-scripts/package_lambda.sh
├── lambda/trigger_glue.py
├── sample-data/sample.csv
├── Makefile
└── README.md
```

## Provisioned Resources

- One S3 bucket for inbound CSV files with EventBridge notifications enabled.
- One S3 bucket for the Iceberg warehouse, Glue script artifact, Spark event logs, and temporary files.
- One S3 bucket for Athena query results.
- One EventBridge rule that watches the configured landing prefix for `*.csv` objects.
- One Lambda function that starts the Glue job through `boto3`.
- One Glue 4.0 ETL job that reads CSV and writes to an Iceberg v2 table in the Glue Catalog.
- One Athena workgroup configured with a dedicated results location.
- CloudWatch log groups for Lambda and Glue plus an alarm on failed Glue Spark tasks.
- One SNS topic with an email subscription for alerting.
- Least-privilege IAM roles for Glue, Lambda, and Athena query access.

## How The Pipeline Works

1. Upload a CSV file into the S3 landing prefix, which defaults to `landing/`.
2. S3 publishes the object creation event to EventBridge.
3. EventBridge invokes Lambda.
4. Lambda extracts the bucket and key, builds an S3 URI, and starts the Glue job.
5. Glue reads the CSV file, normalizes column names, enriches it with ingestion metadata, and writes the dataset to an Iceberg table.
6. Athena queries the Iceberg table through the Glue Data Catalog.
7. CloudWatch stores logs and metrics. If Glue reports failed Spark tasks, CloudWatch Alarm sends a notification to SNS.

## Prerequisites

- Terraform 1.5 or later
- AWS CLI configured with credentials that can create IAM, S3, Glue, Athena, EventBridge, Lambda, CloudWatch, and SNS resources
- Python 3 available locally if you want to package Lambda with the helper script

## Setup

1. Update `environments/dev/terraform.tfvars` with the AWS region you want to use and a real `sns_email` value that you can confirm.
2. The dev tfvars file sets `force_destroy = true` so that `make destroy` can clean up buckets after test uploads. Flip it to `false` if you want stricter protection against accidental bucket deletion.
3. From the repository root, initialize and apply Terraform:

```bash
make init
make plan
make apply
```

4. Confirm the SNS email subscription in your inbox.
5. Upload the sample file into the landing prefix:

```bash
aws s3 cp sample-data/sample.csv s3://$(terraform -chdir=environments/dev output -raw input_bucket_name)/landing/sample.csv
```

6. Watch the Lambda and Glue logs in CloudWatch, then query Athena after the Glue run finishes.

## Querying Athena

Use the provisioned workgroup from Terraform outputs. The Glue job creates the database automatically through Terraform and creates the Iceberg table on the first successful file ingestion.

Sample query:

```sql
SELECT
  event_type,
  COUNT(*) AS event_count,
  SUM(amount) AS gross_amount
FROM aws_iceberg_data_platform_dev.raw_events
GROUP BY event_type
ORDER BY event_count DESC;
```

You can also inspect ingestion metadata:

```sql
SELECT source_bucket, source_key, event_date, ingested_at
FROM aws_iceberg_data_platform_dev.raw_events
ORDER BY ingested_at DESC
LIMIT 10;
```

## Terraform Commands

```bash
make fmt
make validate
make init
make plan
make apply
make destroy
```

## Operational Notes

- The backend is local by default to keep bootstrap simple. Move to an S3 backend with state locking when you promote this beyond a demo or personal sandbox.
- Bucket names are deterministic and globally unique because they include the AWS account ID and region.
- The Glue script is uploaded to the warehouse bucket by Terraform, so `script_location` always points at a real S3 object.
- The landing prefix keeps EventBridge from firing on warehouse artifacts or unrelated objects.
- The Glue job uses Iceberg table format version 2 and appends new files after the table exists. Basic schema evolution is handled by adding newly observed columns before append.

## Interview Talking Points

1. Why choose EventBridge plus Lambda instead of direct S3 to Lambda notifications?
2. What does Apache Iceberg solve compared with plain Parquet on S3?
3. How does the Glue Data Catalog help Athena query Iceberg tables?
4. What are the tradeoffs of partitioning by `event_date` instead of an event timestamp from the raw file?
5. How would you harden this pipeline for production with CI/CD, remote state, and data quality checks?
6. How would you evolve this design to support incremental upserts and deduplication?
7. When would you add Lake Formation, KMS encryption, or VPC endpoints to the stack?
