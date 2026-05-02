variable "lambda_log_group_name" {
  description = "Lambda log group name."
  type        = string
}

variable "glue_log_group_name" {
  description = "Glue log group name."
  type        = string
}

variable "glue_job_name" {
  description = "Glue job name used for the failure alarm."
  type        = string
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period."
  type        = number
}

variable "sns_topic_arn" {
  description = "SNS topic used for alarm notifications."
  type        = string
}

variable "tags" {
  description = "Tags applied to CloudWatch resources."
  type        = map(string)
}
