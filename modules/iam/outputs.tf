output "glue_role_arn" {
  description = "Glue execution role ARN."
  value       = aws_iam_role.glue.arn
}

output "lambda_role_arn" {
  description = "Lambda execution role ARN."
  value       = aws_iam_role.lambda.arn
}

output "athena_role_arn" {
  description = "Athena query role ARN."
  value       = aws_iam_role.athena.arn
}
