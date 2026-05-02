variable "function_name" {
  description = "Lambda function name."
  type        = string
}

variable "role_arn" {
  description = "Lambda execution role ARN."
  type        = string
}

variable "glue_job_name" {
  description = "Glue job started by the function."
  type        = string
}

variable "source_dir" {
  description = "Local directory containing the Lambda source file."
  type        = string
}

variable "handler_file" {
  description = "Python source file that contains the Lambda handler."
  type        = string
  default     = "trigger_glue.py"
}

variable "runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "Lambda memory size in MB."
  type        = number
  default     = 256
}

variable "tags" {
  description = "Tags applied to the Lambda function."
  type        = map(string)
}
