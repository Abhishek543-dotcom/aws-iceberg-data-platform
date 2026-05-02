variable "job_name" {
  description = "Glue job name."
  type        = string
}

variable "role_arn" {
  description = "Glue execution role ARN."
  type        = string
}

variable "database_name" {
  description = "Glue Catalog database used for Iceberg."
  type        = string
}

variable "table_name" {
  description = "Target Iceberg table name."
  type        = string
}

variable "warehouse_bucket_name" {
  description = "S3 bucket used for the Glue script and Iceberg warehouse."
  type        = string
}

variable "script_local_path" {
  description = "Local path to the Glue ETL script."
  type        = string
}

variable "cloudwatch_log_group_name" {
  description = "CloudWatch Logs group for Glue continuous logging."
  type        = string
}

variable "glue_version" {
  description = "Glue version."
  type        = string
  default     = "4.0"
}

variable "number_of_workers" {
  description = "Glue job worker count."
  type        = number
  default     = 2
}

variable "worker_type" {
  description = "Glue worker type."
  type        = string
  default     = "G.1X"
}

variable "timeout_minutes" {
  description = "Glue job timeout in minutes."
  type        = number
}

variable "max_retries" {
  description = "Maximum number of Glue job retries."
  type        = number
}

variable "tags" {
  description = "Tags applied to Glue resources."
  type        = map(string)
}
