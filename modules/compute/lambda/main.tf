data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "lambda" {
  name = "${local.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.function_name}-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count      = local.enable_vpc ? 1 : 0
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "additional" {
  count      = length(var.additional_iam_policies)
  role       = aws_iam_role.lambda.name
  policy_arn = var.additional_iam_policies[count.index]
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.log_kms_key_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.function_name}-logs"
    }
  )
}

resource "aws_lambda_function" "this" {
  function_name = local.function_name
  description   = var.description
  role          = aws_iam_role.lambda.arn

  runtime       = var.runtime
  handler       = var.handler
  memory_size   = var.memory_size
  timeout       = var.timeout
  architectures = var.architectures
  publish       = var.publish
  layers        = var.layers

  filename         = var.filename
  source_code_hash = var.source_code_hash

  s3_bucket         = var.s3_bucket
  s3_key            = var.s3_key
  s3_object_version = var.s3_object_version

  reserved_concurrent_executions = var.reserved_concurrent_executions

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = local.enable_vpc ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != null ? [1] : []
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.function_name
    }
  )

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic,
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_cloudwatch_log_group.lambda,
  ]
}

resource "aws_lambda_event_source_mapping" "this" {
  count = length(var.event_source_mapping)

  event_source_arn                   = var.event_source_mapping[count.index].event_source_arn
  function_name                      = aws_lambda_function.this.arn
  batch_size                         = var.event_source_mapping[count.index].batch_size
  starting_position                  = var.event_source_mapping[count.index].starting_position
  enabled                            = var.event_source_mapping[count.index].enabled
  maximum_batching_window_in_seconds = var.event_source_mapping[count.index].maximum_batching_window_in_seconds
  maximum_retry_attempts             = var.event_source_mapping[count.index].maximum_retry_attempts
  bisect_batch_on_function_error     = var.event_source_mapping[count.index].bisect_batch_on_function_error
}
