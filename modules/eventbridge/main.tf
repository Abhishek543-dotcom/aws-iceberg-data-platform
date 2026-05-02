locals {
  object_key_wildcard = var.object_key_prefix == "" ? "*${var.object_key_suffix}" : "${var.object_key_prefix}*${var.object_key_suffix}"
}

resource "aws_cloudwatch_event_rule" "s3_object_created" {
  name        = var.rule_name
  description = "Routes landing-zone CSV uploads from S3 to the Glue-triggering Lambda."

  event_pattern = jsonencode({
    source        = ["aws.s3"]
    "detail-type" = ["Object Created"]
    detail = {
      bucket = {
        name = [var.input_bucket_name]
      }
      object = {
        key = [
          {
            wildcard = local.object_key_wildcard
          }
        ]
      }
    }
  })

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.s3_object_created.name
  target_id = "InvokeGlueTriggerLambda"
  arn       = var.lambda_function_arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.s3_object_created.arn
}
