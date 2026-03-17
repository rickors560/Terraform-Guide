###############################################################################
# API Gateway Component — REST API with Lambda, Stages, API Key, Usage Plan
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
  #   key            = "components/api-gateway/terraform.tfstate"
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
      Component   = "api-gateway"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Lambda Backend (inline Python function)
# -----------------------------------------------------------------------------

data "archive_file" "lambda" {
  type        = "zip"
  output_path = "${path.module}/api_handler.zip"

  source {
    content = <<-PYTHON
import json
import os
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """API Gateway backend handler."""
    logger.info("Event: %s", json.dumps(event))

    method = event.get("httpMethod", "GET")
    path = event.get("path", "/")
    query = event.get("queryStringParameters") or {}
    body_str = event.get("body")

    response_body = {
        "message": "Success",
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "method": method,
        "path": path,
        "query": query,
        "environment": os.environ.get("ENVIRONMENT", "unknown"),
    }

    if body_str:
        try:
            response_body["received_body"] = json.loads(body_str)
        except json.JSONDecodeError:
            response_body["received_body"] = body_str

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET,POST,PUT,DELETE,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type,X-Api-Key,Authorization",
        },
        "body": json.dumps(response_body, indent=2),
    }
    PYTHON

    filename = "api_handler.py"
  }
}

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-${var.environment}-api-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_logs" {
  name = "cloudwatch-logs"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
    }]
  })
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-api-handler"
  retention_in_days = 30
}

resource "aws_lambda_function" "api_handler" {
  function_name    = "${var.project_name}-${var.environment}-api-handler"
  description      = "API Gateway backend handler"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  handler          = "api_handler.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda.arn
  memory_size      = 128
  timeout          = 30

  environment {
    variables = {
      ENVIRONMENT  = var.environment
      PROJECT_NAME = var.project_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]

  tags = {
    Name = "${var.project_name}-${var.environment}-api-handler"
  }
}

# -----------------------------------------------------------------------------
# REST API
# -----------------------------------------------------------------------------

resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-${var.environment}-api"
  description = "REST API for ${var.project_name} (${var.environment})"

  endpoint_configuration {
    types = [var.endpoint_type]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-api"
  }
}

# -----------------------------------------------------------------------------
# Resources and Methods
# -----------------------------------------------------------------------------

# /api resource
resource "aws_api_gateway_resource" "api" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "api"
}

# /api/{proxy+} resource
resource "aws_api_gateway_resource" "api_proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.api.id
  path_part   = "{proxy+}"
}

# ANY /api/{proxy+}
resource "aws_api_gateway_method" "api_proxy" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.api_proxy.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = var.require_api_key
}

resource "aws_api_gateway_integration" "api_proxy" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.api_proxy.id
  http_method             = aws_api_gateway_method.api_proxy.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# ANY /api
resource "aws_api_gateway_method" "api_root" {
  rest_api_id      = aws_api_gateway_rest_api.main.id
  resource_id      = aws_api_gateway_resource.api.id
  http_method      = "ANY"
  authorization    = "NONE"
  api_key_required = var.require_api_key
}

resource "aws_api_gateway_integration" "api_root" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.api.id
  http_method             = aws_api_gateway_method.api_root.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_handler.invoke_arn
}

# OPTIONS (CORS preflight) on /api/{proxy+}
resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.api_proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.api_proxy.id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.api_proxy.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.api_proxy.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Api-Key,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,PUT,DELETE,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.options]
}

# -----------------------------------------------------------------------------
# Lambda Permission
# -----------------------------------------------------------------------------

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# -----------------------------------------------------------------------------
# Deployment and Stages
# -----------------------------------------------------------------------------

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.api.id,
      aws_api_gateway_resource.api_proxy.id,
      aws_api_gateway_method.api_proxy.id,
      aws_api_gateway_integration.api_proxy.id,
      aws_api_gateway_method.api_root.id,
      aws_api_gateway_integration.api_root.id,
      aws_api_gateway_method.options.id,
      aws_api_gateway_integration.options.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access.arn
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
      integrationLatency = "$context.integrationLatency"
    })
  }

  xray_tracing_enabled = var.xray_tracing_enabled

  tags = {
    Name = "${var.project_name}-${var.environment}-api-stage"
  }
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
    metrics_enabled        = true
    logging_level          = "INFO"
    data_trace_enabled     = var.environment != "prod"
  }
}

resource "aws_cloudwatch_log_group" "api_access" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}-api/access"
  retention_in_days = 30
}

# -----------------------------------------------------------------------------
# API Key and Usage Plan
# -----------------------------------------------------------------------------

resource "aws_api_gateway_api_key" "main" {
  count = var.require_api_key ? 1 : 0

  name        = "${var.project_name}-${var.environment}-api-key"
  description = "API key for ${var.project_name}-${var.environment}"
  enabled     = true

  tags = {
    Name = "${var.project_name}-${var.environment}-api-key"
  }
}

resource "aws_api_gateway_usage_plan" "main" {
  count = var.require_api_key ? 1 : 0

  name        = "${var.project_name}-${var.environment}-usage-plan"
  description = "Usage plan for ${var.project_name}-${var.environment}"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.main.stage_name
  }

  quota_settings {
    limit  = var.usage_plan_quota_limit
    period = "MONTH"
  }

  throttle_settings {
    burst_limit = var.throttling_burst_limit
    rate_limit  = var.throttling_rate_limit
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-usage-plan"
  }
}

resource "aws_api_gateway_usage_plan_key" "main" {
  count = var.require_api_key ? 1 : 0

  key_id        = aws_api_gateway_api_key.main[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main[0].id
}

# -----------------------------------------------------------------------------
# WAF Web ACL (optional, for enhanced security)
# NOTE: Uncomment and configure if WAFv2 protection is needed.
# Custom domain requires an ACM certificate — see the acm component.
# -----------------------------------------------------------------------------
