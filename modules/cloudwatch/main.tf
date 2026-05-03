resource "aws_cloudwatch_log_group" "lambda" {
  name              = var.lambda_log_group_name
  retention_in_days = var.log_retention_days
  skip_destroy      = var.preserve_logs_on_destroy
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "glue" {
  name              = var.glue_log_group_name
  retention_in_days = var.log_retention_days
  skip_destroy      = var.preserve_logs_on_destroy
  tags              = var.tags
}

resource "aws_cloudwatch_metric_alarm" "glue_failed_tasks" {
  alarm_name          = "${var.glue_job_name}-failed-tasks"
  alarm_description   = "Triggers when the AWS Glue job reports failed Spark tasks."
  namespace           = "Glue"
  metric_name         = "glue.driver.aggregate.numFailedTasks"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  alarm_actions       = [var.sns_topic_arn]

  dimensions = {
    JobName  = var.glue_job_name
    JobRunId = "ALL"
    Type     = "count"
  }

  tags = var.tags
}
