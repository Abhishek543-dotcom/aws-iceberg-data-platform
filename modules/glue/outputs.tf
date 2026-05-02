output "job_name" {
  description = "Glue job name."
  value       = aws_glue_job.this.name
}

output "job_arn" {
  description = "Glue job ARN."
  value       = aws_glue_job.this.arn
}

output "database_name" {
  description = "Glue database name."
  value       = aws_glue_catalog_database.this.name
}

output "table_name" {
  description = "Target Iceberg table name."
  value       = var.table_name
}

output "script_s3_uri" {
  description = "S3 URI of the uploaded Glue script."
  value       = "s3://${var.warehouse_bucket_name}/${aws_s3_object.script.key}"
}
