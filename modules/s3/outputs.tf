output "input_bucket_name" {
  description = "Input bucket name."
  value       = aws_s3_bucket.buckets["input"].bucket
}

output "input_bucket_arn" {
  description = "Input bucket ARN."
  value       = aws_s3_bucket.buckets["input"].arn
}

output "warehouse_bucket_name" {
  description = "Warehouse bucket name."
  value       = aws_s3_bucket.buckets["warehouse"].bucket
}

output "warehouse_bucket_arn" {
  description = "Warehouse bucket ARN."
  value       = aws_s3_bucket.buckets["warehouse"].arn
}

output "athena_results_bucket_name" {
  description = "Athena results bucket name."
  value       = aws_s3_bucket.buckets["athena_results"].bucket
}

output "athena_results_bucket_arn" {
  description = "Athena results bucket ARN."
  value       = aws_s3_bucket.buckets["athena_results"].arn
}
