variable "name_prefix" {
  description = "Project and environment prefix used in IAM resource names."
  type        = string
}

variable "account_id" {
  description = "Current AWS account ID."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "input_bucket_arn" {
  description = "ARN of the source input bucket."
  type        = string
}

variable "warehouse_bucket_arn" {
  description = "ARN of the Iceberg warehouse bucket."
  type        = string
}

variable "athena_results_bucket_arn" {
  description = "ARN of the Athena results bucket."
  type        = string
}

variable "glue_database_name" {
  description = "Glue database name."
  type        = string
}

variable "glue_job_name" {
  description = "Glue job name."
  type        = string
}

variable "glue_log_group_name" {
  description = "CloudWatch log group name for Glue continuous logs."
  type        = string
}

variable "lambda_log_group_name" {
  description = "CloudWatch log group name for Lambda."
  type        = string
}

variable "athena_workgroup_name" {
  description = "Athena workgroup name."
  type        = string
}

variable "athena_trusted_principal_arns" {
  description = "IAM principals allowed to assume the Athena role."
  type        = list(string)
}

variable "tags" {
  description = "Tags applied to IAM resources."
  type        = map(string)
}
