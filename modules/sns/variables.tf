variable "topic_name" {
  description = "SNS topic name."
  type        = string
}

variable "email_endpoint" {
  description = "Email address subscribed to the SNS topic."
  type        = string
}

variable "tags" {
  description = "Tags applied to SNS resources."
  type        = map(string)
}
