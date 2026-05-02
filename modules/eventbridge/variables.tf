variable "rule_name" {
  description = "EventBridge rule name."
  type        = string
}

variable "input_bucket_name" {
  description = "S3 bucket name matched by the rule."
  type        = string
}

variable "object_key_prefix" {
  description = "S3 key prefix to match."
  type        = string
}

variable "object_key_suffix" {
  description = "S3 key suffix to match."
  type        = string
}

variable "lambda_function_arn" {
  description = "Lambda function ARN invoked by EventBridge."
  type        = string
}

variable "lambda_function_name" {
  description = "Lambda function name invoked by EventBridge."
  type        = string
}

variable "tags" {
  description = "Tags applied to EventBridge resources."
  type        = map(string)
}
