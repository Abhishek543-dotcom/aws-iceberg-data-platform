variable "workgroup_name" {
  description = "Athena workgroup name."
  type        = string
}

variable "results_bucket_name" {
  description = "S3 bucket for Athena result sets."
  type        = string
}

variable "tags" {
  description = "Tags applied to the Athena workgroup."
  type        = map(string)
}
