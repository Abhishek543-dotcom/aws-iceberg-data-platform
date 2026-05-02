variable "input_bucket_name" {
  description = "Name of the inbound data bucket."
  type        = string
}

variable "warehouse_bucket_name" {
  description = "Name of the Iceberg warehouse bucket."
  type        = string
}

variable "athena_results_bucket_name" {
  description = "Name of the Athena query results bucket."
  type        = string
}

variable "force_destroy" {
  description = "Whether to allow bucket deletion when non-empty."
  type        = bool
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
}
