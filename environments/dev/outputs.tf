output "input_bucket_name" {
  description = "Bucket that receives source CSV files."
  value       = module.s3.input_bucket_name
}

output "warehouse_bucket_name" {
  description = "Bucket that stores Iceberg metadata and data files."
  value       = module.s3.warehouse_bucket_name
}

output "athena_results_bucket_name" {
  description = "Bucket used for Athena query results."
  value       = module.s3.athena_results_bucket_name
}

output "glue_database_name" {
  description = "Glue Catalog database created for the Iceberg lakehouse."
  value       = module.glue.database_name
}

output "iceberg_table_name" {
  description = "Iceberg table populated by the Glue job."
  value       = module.glue.table_name
}

output "glue_job_name" {
  description = "AWS Glue job started by Lambda."
  value       = module.glue.job_name
}

output "lambda_function_name" {
  description = "Lambda function invoked by EventBridge."
  value       = module.lambda.function_name
}

output "athena_workgroup_name" {
  description = "Athena workgroup for analytics queries."
  value       = module.athena.workgroup_name
}

output "athena_access_role_arn" {
  description = "IAM role that grants least-privilege Athena query access."
  value       = module.iam.athena_role_arn
}

output "sns_topic_arn" {
  description = "SNS topic that receives operational alerts."
  value       = module.sns.topic_arn
}

output "glue_log_group_name" {
  description = "CloudWatch log group used by the Glue job continuous logs."
  value       = module.cloudwatch.glue_log_group_name
}

output "lambda_log_group_name" {
  description = "CloudWatch log group used by the trigger Lambda."
  value       = module.cloudwatch.lambda_log_group_name
}

output "sample_upload_command" {
  description = "CLI command that uploads the sample CSV to the monitored landing prefix."
  value       = "aws s3 cp ../../sample-data/sample.csv s3://${module.s3.input_bucket_name}/${local.normalized_input_prefix}sample.csv"
}
