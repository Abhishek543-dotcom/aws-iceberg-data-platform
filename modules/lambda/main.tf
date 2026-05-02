locals {
  handler_module = trimsuffix(var.handler_file, ".py")
}

data "archive_file" "package" {
  type        = "zip"
  source_file = "${var.source_dir}/${var.handler_file}"
  output_path = "${var.source_dir}/${var.function_name}.zip"
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.role_arn
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size
  filename      = data.archive_file.package.output_path
  handler       = "${local.handler_module}.lambda_handler"

  source_code_hash = data.archive_file.package.output_base64sha256

  environment {
    variables = {
      GLUE_JOB_NAME = var.glue_job_name
    }
  }

  tags = var.tags
}
