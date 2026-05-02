variable "aws_region" {
  description = "AWS region for the deployment."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "project_name" {
  description = "Project name used in resource names."
  type        = string
}

variable "input_prefix" {
  description = "S3 prefix monitored for inbound CSV files."
  type        = string
}

variable "sns_email" {
  description = "Email address subscribed to operational alerts."
  type        = string
}

variable "force_destroy" {
  description = "Whether Terraform may delete non-empty buckets during destroy."
  type        = bool
}

variable "log_retention_days" {
  description = "CloudWatch log retention for Lambda and Glue."
  type        = number
}

variable "glue_timeout_minutes" {
  description = "Glue job timeout in minutes."
  type        = number
}

variable "glue_max_retries" {
  description = "Number of Glue job retries."
  type        = number
}

variable "athena_trusted_principal_arns" {
  description = "Optional IAM principals allowed to assume the Athena query role. Defaults to the current account root principal."
  type        = list(string)
}
