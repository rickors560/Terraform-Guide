###############################################################################
# Lambda Component — Python Function with IAM, CloudWatch, API Gateway Trigger
###############################################################################

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "components/lambda/terraform.tfstate"
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "lambda"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Lambda Source Code (inline via archive)
# -----------------------------------------------------------------------------

data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.module}/lambda_function.zip"

  source {
    content = <<-PYTHON
import json
import os
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Main Lambda handler function.
    Responds to API Gateway requests with a JSON greeting.
    """
    logger.info("Received event: %s", json.dumps(event))

    # Extract request details
    http_method = event.get("httpMethod", "UNKNOWN")
    path = event.get("path", "/")
    query_params = event.get("queryStringParameters") or {}
    headers = event.get("headers") or {}

    # Get name from query string or default
    name = query_params.get("name", "World")

    # Build response body
    body = {
        "message": f"Hello, {name}!",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "environment": os.environ.get("ENVIRONMENT", "unknown"),
        "project": os.environ.get("PROJECT_NAME", "unknown"),
        "request": {
            "method": http_method,
            "path": path,
        },
        "function": {
            "name": context.function_name,
            "version": context.function_version,
            "memory_limit_mb": context.memory_limit_in_mb,
            "remaining_time_ms": context.get_remaining_time_in_millis(),
        },
    }

    logger.info("Response body: %s", json.dumps(body))

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "X-Request-Id": context.aws_request_id,
        },
        "body": json.dumps(body, indent=2),
    }
    PYTHON

    filename = "lambda_function.py"
  }
}

# -----------------------------------------------------------------------------
# IAM Role and Policies
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-${var.environment}-lambda-role"

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

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-role"
  }
}

resource "aws_iam_role_policy" "lambda_logging" {
  name = "${var.project_name}-${var.environment}-lambda-logging"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      }
    ]
  })
}

# Optional VPC access policy
resource "aws_iam_role_policy_attachment" "vpc_access" {
  count = length(var.vpc_subnet_ids) > 0 ? 1 : 0

  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Optional X-Ray tracing policy
resource "aws_iam_role_policy_attachment" "xray" {
  count = var.tracing_mode != "PassThrough" ? 1 : 0

  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group (created before Lambda to control retention)
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-function"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-logs"
  }
}

# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------

resource "aws_lambda_function" "main" {
  function_name = "${var.project_name}-${var.environment}-function"
  description   = "${var.project_name} Lambda function (${var.environment})"

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"

  role        = aws_iam_role.lambda.arn
  memory_size = var.memory_size
  timeout     = var.timeout

  reserved_concurrent_executions = var.reserved_concurrency

  environment {
    variables = merge(
      {
        ENVIRONMENT  = var.environment
        PROJECT_NAME = var.project_name
        LOG_LEVEL    = var.log_level
      },
      var.extra_environment_variables
    )
  }

  tracing_config {
    mode = var.tracing_mode
  }

  dynamic "vpc_config" {
    for_each = length(var.vpc_subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_logging,
    aws_cloudwatch_log_group.lambda,
  ]

  tags = {
    Name = "${var.project_name}-${var.environment}-function"
  }
}

# -----------------------------------------------------------------------------
# API Gateway (REST API) — Simple trigger for the Lambda
# -----------------------------------------------------------------------------

resource "aws_api_gateway_rest_api" "main" {
  count = var.create_api_gateway ? 1 : 0

  name        = "${var.project_name}-${var.environment}-api"
  description = "REST API for ${var.project_name}-${var.environment} Lambda"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-api"
  }
}

resource "aws_api_gateway_resource" "proxy" {
  count = var.create_api_gateway ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main[0].id
  parent_id   = aws_api_gateway_rest_api.main[0].root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
  count = var.create_api_gateway ? 1 : 0

  rest_api_id   = aws_api_gateway_rest_api.main[0].id
  resource_id   = aws_api_gateway_resource.proxy[0].id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "proxy" {
  count = var.create_api_gateway ? 1 : 0

  rest_api_id             = aws_api_gateway_rest_api.main[0].id
  resource_id             = aws_api_gateway_resource.proxy[0].id
  http_method             = aws_api_gateway_method.proxy[0].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main.invoke_arn
}

resource "aws_api_gateway_method" "root" {
  count = var.create_api_gateway ? 1 : 0

  rest_api_id   = aws_api_gateway_rest_api.main[0].id
  resource_id   = aws_api_gateway_rest_api.main[0].root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "root" {
  count = var.create_api_gateway ? 1 : 0

  rest_api_id             = aws_api_gateway_rest_api.main[0].id
  resource_id             = aws_api_gateway_rest_api.main[0].root_resource_id
  http_method             = aws_api_gateway_method.root[0].http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.main.invoke_arn
}

resource "aws_api_gateway_deployment" "main" {
  count = var.create_api_gateway ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.main[0].id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy[0].id,
      aws_api_gateway_method.proxy[0].id,
      aws_api_gateway_integration.proxy[0].id,
      aws_api_gateway_method.root[0].id,
      aws_api_gateway_integration.root[0].id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  count = var.create_api_gateway ? 1 : 0

  deployment_id = aws_api_gateway_deployment.main[0].id
  rest_api_id   = aws_api_gateway_rest_api.main[0].id
  stage_name    = var.environment

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw[0].arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-api-stage"
  }
}

resource "aws_cloudwatch_log_group" "api_gw" {
  count = var.create_api_gateway ? 1 : 0

  name              = "/aws/apigateway/${var.project_name}-${var.environment}-api"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-${var.environment}-api-gw-logs"
  }
}

# -----------------------------------------------------------------------------
# Lambda Permission for API Gateway
# -----------------------------------------------------------------------------

resource "aws_lambda_permission" "api_gateway" {
  count = var.create_api_gateway ? 1 : 0

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main[0].execution_arn}/*/*"
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "errors" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Lambda function errors exceeding threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.main.function_name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-errors-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "throttles" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Lambda function is being throttled"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.main.function_name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-throttles-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "duration" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-duration-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 300
  statistic           = "Average"
  threshold           = var.timeout * 1000 * 0.8 # 80% of timeout
  alarm_description   = "Lambda function duration approaching timeout"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = aws_lambda_function.main.function_name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-duration-alarm"
  }
}
