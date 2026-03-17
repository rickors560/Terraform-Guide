###############################################################################
# Example 04 — Serverless API: API Gateway + Lambda + DynamoDB
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
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

###############################################################################
# DynamoDB Table
###############################################################################

resource "aws_dynamodb_table" "items" {
  name         = "${var.project_name}-items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = { Name = "${var.project_name}-items" }
}

###############################################################################
# IAM Role for Lambda
###############################################################################

resource "aws_iam_role" "lambda" {
  name = "${var.project_name}-lambda-role"

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

  tags = { Name = "${var.project_name}-lambda-role" }
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.project_name}-lambda-dynamodb"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
        ]
        Resource = [
          aws_dynamodb_table.items.arn,
          "${aws_dynamodb_table.items.arn}/index/*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

###############################################################################
# CloudWatch Log Groups
###############################################################################

resource "aws_cloudwatch_log_group" "create_item" {
  name              = "/aws/lambda/${var.project_name}-create-item"
  retention_in_days = 14
  tags              = { Name = "${var.project_name}-create-item-logs" }
}

resource "aws_cloudwatch_log_group" "get_item" {
  name              = "/aws/lambda/${var.project_name}-get-item"
  retention_in_days = 14
  tags              = { Name = "${var.project_name}-get-item-logs" }
}

resource "aws_cloudwatch_log_group" "list_items" {
  name              = "/aws/lambda/${var.project_name}-list-items"
  retention_in_days = 14
  tags              = { Name = "${var.project_name}-list-items-logs" }
}

resource "aws_cloudwatch_log_group" "delete_item" {
  name              = "/aws/lambda/${var.project_name}-delete-item"
  retention_in_days = 14
  tags              = { Name = "${var.project_name}-delete-item-logs" }
}

###############################################################################
# Lambda Source Code (archive_file data sources)
###############################################################################

data "archive_file" "create_item" {
  type        = "zip"
  output_path = "${path.module}/.build/create_item.zip"

  source {
    content  = file("${path.module}/src/create_item.py")
    filename = "create_item.py"
  }
}

data "archive_file" "get_item" {
  type        = "zip"
  output_path = "${path.module}/.build/get_item.zip"

  source {
    content  = file("${path.module}/src/get_item.py")
    filename = "get_item.py"
  }
}

data "archive_file" "list_items" {
  type        = "zip"
  output_path = "${path.module}/.build/list_items.zip"

  source {
    content  = file("${path.module}/src/list_items.py")
    filename = "list_items.py"
  }
}

data "archive_file" "delete_item" {
  type        = "zip"
  output_path = "${path.module}/.build/delete_item.zip"

  source {
    content  = file("${path.module}/src/delete_item.py")
    filename = "delete_item.py"
  }
}

###############################################################################
# Lambda Functions
###############################################################################

resource "aws_lambda_function" "create_item" {
  function_name    = "${var.project_name}-create-item"
  role             = aws_iam_role.lambda.arn
  handler          = "create_item.handler"
  runtime          = "python3.12"
  timeout          = 10
  memory_size      = 128
  filename         = data.archive_file.create_item.output_path
  source_code_hash = data.archive_file.create_item.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.items.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.create_item]

  tags = { Name = "${var.project_name}-create-item" }
}

resource "aws_lambda_function" "get_item" {
  function_name    = "${var.project_name}-get-item"
  role             = aws_iam_role.lambda.arn
  handler          = "get_item.handler"
  runtime          = "python3.12"
  timeout          = 10
  memory_size      = 128
  filename         = data.archive_file.get_item.output_path
  source_code_hash = data.archive_file.get_item.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.items.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.get_item]

  tags = { Name = "${var.project_name}-get-item" }
}

resource "aws_lambda_function" "list_items" {
  function_name    = "${var.project_name}-list-items"
  role             = aws_iam_role.lambda.arn
  handler          = "list_items.handler"
  runtime          = "python3.12"
  timeout          = 10
  memory_size      = 128
  filename         = data.archive_file.list_items.output_path
  source_code_hash = data.archive_file.list_items.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.items.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.list_items]

  tags = { Name = "${var.project_name}-list-items" }
}

resource "aws_lambda_function" "delete_item" {
  function_name    = "${var.project_name}-delete-item"
  role             = aws_iam_role.lambda.arn
  handler          = "delete_item.handler"
  runtime          = "python3.12"
  timeout          = 10
  memory_size      = 128
  filename         = data.archive_file.delete_item.output_path
  source_code_hash = data.archive_file.delete_item.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.items.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.delete_item]

  tags = { Name = "${var.project_name}-delete-item" }
}

###############################################################################
# API Gateway REST API
###############################################################################

resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-api"
  description = "Serverless CRUD API for ${var.project_name}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = { Name = "${var.project_name}-api" }
}

# /items resource
resource "aws_api_gateway_resource" "items" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "items"
}

# /items/{id} resource
resource "aws_api_gateway_resource" "item" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.items.id
  path_part   = "{id}"
}

###############################################################################
# POST /items — create_item
###############################################################################

resource "aws_api_gateway_method" "create_item" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create_item" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.items.id
  http_method             = aws_api_gateway_method.create_item.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_item.invoke_arn
}

resource "aws_lambda_permission" "create_item" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_item.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

###############################################################################
# GET /items — list_items
###############################################################################

resource "aws_api_gateway_method" "list_items" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "list_items" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.items.id
  http_method             = aws_api_gateway_method.list_items.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.list_items.invoke_arn
}

resource "aws_lambda_permission" "list_items" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.list_items.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

###############################################################################
# GET /items/{id} — get_item
###############################################################################

resource "aws_api_gateway_method" "get_item" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.item.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_item" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.item.id
  http_method             = aws_api_gateway_method.get_item.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_item.invoke_arn
}

resource "aws_lambda_permission" "get_item" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_item.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

###############################################################################
# DELETE /items/{id} — delete_item
###############################################################################

resource "aws_api_gateway_method" "delete_item" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.item.id
  http_method   = "DELETE"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "delete_item" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.item.id
  http_method             = aws_api_gateway_method.delete_item.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.delete_item.invoke_arn
}

resource "aws_lambda_permission" "delete_item" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_item.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

###############################################################################
# API Gateway Deployment & Stages
###############################################################################

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.items.id,
      aws_api_gateway_resource.item.id,
      aws_api_gateway_method.create_item.id,
      aws_api_gateway_method.get_item.id,
      aws_api_gateway_method.list_items.id,
      aws_api_gateway_method.delete_item.id,
      aws_api_gateway_integration.create_item.id,
      aws_api_gateway_integration.get_item.id,
      aws_api_gateway_integration.list_items.id,
      aws_api_gateway_integration.delete_item.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "dev"

  variables = {
    environment = "dev"
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_dev.arn
  }

  tags = { Name = "${var.project_name}-dev-stage" }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = "prod"

  variables = {
    environment = "prod"
  }

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_prod.arn
  }

  tags = { Name = "${var.project_name}-prod-stage" }
}

resource "aws_cloudwatch_log_group" "api_gw_dev" {
  name              = "/aws/apigateway/${var.project_name}-dev"
  retention_in_days = 14
  tags              = { Name = "${var.project_name}-apigw-dev-logs" }
}

resource "aws_cloudwatch_log_group" "api_gw_prod" {
  name              = "/aws/apigateway/${var.project_name}-prod"
  retention_in_days = 30
  tags              = { Name = "${var.project_name}-apigw-prod-logs" }
}

resource "aws_api_gateway_method_settings" "dev" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.dev.stage_name
  method_path = "*/*"

  settings {
    logging_level      = "INFO"
    data_trace_enabled = true
    metrics_enabled    = true
  }
}

resource "aws_api_gateway_method_settings" "prod" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    logging_level      = "ERROR"
    data_trace_enabled = false
    metrics_enabled    = true
  }
}
