output "lambda_log_group_name" {
  description = "Lambda log group name."
  value       = aws_cloudwatch_log_group.lambda.name
}

output "glue_log_group_name" {
  description = "Glue log group name."
  value       = aws_cloudwatch_log_group.glue.name
}

output "glue_failure_alarm_arn" {
  description = "Glue failure alarm ARN."
  value       = aws_cloudwatch_metric_alarm.glue_failed_tasks.arn
}
