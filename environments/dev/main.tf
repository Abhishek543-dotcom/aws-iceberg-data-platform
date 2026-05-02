terraform {
  required_version = ">= 1.5.0"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.5"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.common_tags
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  name_prefix                   = "${var.project_name}-${var.environment}"
  normalized_input_prefix       = trim(var.input_prefix, "/") == "" ? "" : "${trim(var.input_prefix, "/")}/"
  glue_database_name            = lower(replace("${var.project_name}_${var.environment}", "-", "_"))
  iceberg_table_name            = "raw_events"
  lambda_function_name          = "${local.name_prefix}-trigger-glue"
  glue_job_name                 = "${local.name_prefix}-csv-to-iceberg"
  athena_workgroup_name         = "${local.name_prefix}-athena"
  eventbridge_rule_name         = "${local.name_prefix}-s3-object-created"
  sns_topic_name                = "${local.name_prefix}-alerts"
  glue_log_group_name           = "/aws/glue/${local.name_prefix}/jobs"
  lambda_log_group_name         = "/aws/lambda/${local.lambda_function_name}"
  input_bucket_name             = lower("${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}-in")
  warehouse_bucket_name         = lower("${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}-wh")
  athena_results_bucket_name    = lower("${var.project_name}-${var.environment}-${data.aws_caller_identity.current.account_id}-ath")
  lambda_source_dir             = abspath("${path.module}/../../lambda")
  glue_script_local_path        = abspath("${path.module}/../../glue/scripts/csv_to_iceberg.py")
  athena_trusted_principal_arns = length(var.athena_trusted_principal_arns) > 0 ? var.athena_trusted_principal_arns : ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "aws-iceberg-data-platform"
  }
}

module "sns" {
  source = "../../modules/sns"

  topic_name     = local.sns_topic_name
  email_endpoint = var.sns_email
  tags           = local.common_tags
}

module "s3" {
  source = "../../modules/s3"

  input_bucket_name          = local.input_bucket_name
  warehouse_bucket_name      = local.warehouse_bucket_name
  athena_results_bucket_name = local.athena_results_bucket_name
  force_destroy              = var.force_destroy
  tags                       = local.common_tags
}

module "cloudwatch" {
  source = "../../modules/cloudwatch"

  lambda_log_group_name = local.lambda_log_group_name
  glue_log_group_name   = local.glue_log_group_name
  glue_job_name         = local.glue_job_name
  log_retention_days    = var.log_retention_days
  sns_topic_arn         = module.sns.topic_arn
  tags                  = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  name_prefix                   = local.name_prefix
  account_id                    = data.aws_caller_identity.current.account_id
  region                        = data.aws_region.current.region
  input_bucket_arn              = module.s3.input_bucket_arn
  warehouse_bucket_arn          = module.s3.warehouse_bucket_arn
  athena_results_bucket_arn     = module.s3.athena_results_bucket_arn
  glue_database_name            = local.glue_database_name
  glue_job_name                 = local.glue_job_name
  glue_log_group_name           = local.glue_log_group_name
  lambda_log_group_name         = local.lambda_log_group_name
  athena_workgroup_name         = local.athena_workgroup_name
  athena_trusted_principal_arns = local.athena_trusted_principal_arns
  tags                          = local.common_tags
}

module "glue" {
  source = "../../modules/glue"

  job_name                  = local.glue_job_name
  role_arn                  = module.iam.glue_role_arn
  database_name             = local.glue_database_name
  table_name                = local.iceberg_table_name
  warehouse_bucket_name     = module.s3.warehouse_bucket_name
  script_local_path         = local.glue_script_local_path
  cloudwatch_log_group_name = local.glue_log_group_name
  max_retries               = var.glue_max_retries
  timeout_minutes           = var.glue_timeout_minutes
  tags                      = local.common_tags

  depends_on = [module.cloudwatch]
}

module "lambda" {
  source = "../../modules/lambda"

  function_name = local.lambda_function_name
  role_arn      = module.iam.lambda_role_arn
  glue_job_name = module.glue.job_name
  source_dir    = local.lambda_source_dir
  tags          = local.common_tags

  depends_on = [module.cloudwatch]
}

module "eventbridge" {
  source = "../../modules/eventbridge"

  rule_name            = local.eventbridge_rule_name
  input_bucket_name    = module.s3.input_bucket_name
  object_key_prefix    = local.normalized_input_prefix
  object_key_suffix    = ".csv"
  lambda_function_arn  = module.lambda.function_arn
  lambda_function_name = module.lambda.function_name
  tags                 = local.common_tags
}

module "athena" {
  source = "../../modules/athena"

  workgroup_name      = local.athena_workgroup_name
  results_bucket_name = module.s3.athena_results_bucket_name
  tags                = local.common_tags
}
