locals {
  glue_catalog_arn             = "arn:aws:glue:${var.region}:${var.account_id}:catalog"
  glue_database_arn            = "arn:aws:glue:${var.region}:${var.account_id}:database/${var.glue_database_name}"
  glue_table_arn               = "arn:aws:glue:${var.region}:${var.account_id}:table/${var.glue_database_name}/*"
  glue_job_arn                 = "arn:aws:glue:${var.region}:${var.account_id}:job/${var.glue_job_name}"
  lambda_log_group_arn         = "arn:aws:logs:${var.region}:${var.account_id}:log-group:${var.lambda_log_group_name}"
  glue_log_group_arn           = "arn:aws:logs:${var.region}:${var.account_id}:log-group:${var.glue_log_group_name}"
  athena_workgroup_arn         = "arn:aws:athena:${var.region}:${var.account_id}:workgroup/${var.athena_workgroup_name}"
  input_bucket_objects_arn     = "${var.input_bucket_arn}/*"
  warehouse_bucket_objects_arn = "${var.warehouse_bucket_arn}/*"
  athena_results_objects_arn   = "${var.athena_results_bucket_arn}/*"
}

data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue" {
  name               = "${var.name_prefix}-glue-role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "glue_access" {
  statement {
    sid = "ReadLandingData"

    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      var.input_bucket_arn,
      local.input_bucket_objects_arn
    ]
  }

  statement {
    sid = "ManageWarehouse"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]

    resources = [
      var.warehouse_bucket_arn,
      local.warehouse_bucket_objects_arn
    ]
  }

  statement {
    sid = "ManageGlueCatalog"

    actions = [
      "glue:CreateDatabase",
      "glue:CreateTable",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetTable",
      "glue:GetTables",
      "glue:BatchCreatePartition",
      "glue:BatchDeletePartition",
      "glue:BatchUpdatePartition",
      "glue:UpdateDatabase",
      "glue:UpdateTable"
    ]

    resources = [
      local.glue_catalog_arn,
      local.glue_database_arn,
      local.glue_table_arn
    ]
  }

  statement {
    sid = "EmitGlueLogs"

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]

    resources = [
      local.glue_log_group_arn,
      "${local.glue_log_group_arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "glue_access" {
  name   = "${var.name_prefix}-glue-access"
  role   = aws_iam_role.glue.id
  policy = data.aws_iam_policy_document.glue_access.json
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "lambda_access" {
  statement {
    sid = "StartGlueJob"

    actions = [
      "glue:GetJob",
      "glue:GetJobRun",
      "glue:StartJobRun"
    ]

    resources = [local.glue_job_arn]
  }

  statement {
    sid = "EmitLambdaLogs"

    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents"
    ]

    resources = [
      local.lambda_log_group_arn,
      "${local.lambda_log_group_arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "lambda_access" {
  name   = "${var.name_prefix}-lambda-access"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda_access.json
}

data "aws_iam_policy_document" "athena_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.athena_trusted_principal_arns
    }
  }
}

resource "aws_iam_role" "athena" {
  name               = "${var.name_prefix}-athena-role"
  assume_role_policy = data.aws_iam_policy_document.athena_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "athena_access" {
  statement {
    sid = "RunAthenaQueries"

    actions = [
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:GetWorkGroup",
      "athena:ListQueryExecutions",
      "athena:StartQueryExecution",
      "athena:StopQueryExecution"
    ]

    resources = [
      local.athena_workgroup_arn,
      "*"
    ]
  }

  statement {
    sid = "ReadCatalog"

    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables"
    ]

    resources = [
      local.glue_catalog_arn,
      local.glue_database_arn,
      local.glue_table_arn
    ]
  }

  statement {
    sid = "ReadIcebergData"

    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      var.warehouse_bucket_arn,
      local.warehouse_bucket_objects_arn
    ]
  }

  statement {
    sid = "ManageQueryResults"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]

    resources = [
      var.athena_results_bucket_arn,
      local.athena_results_objects_arn
    ]
  }
}

resource "aws_iam_role_policy" "athena_access" {
  name   = "${var.name_prefix}-athena-access"
  role   = aws_iam_role.athena.id
  policy = data.aws_iam_policy_document.athena_access.json
}
