# -----------------------------------------------------------------------------
# Step Functions Component - Order Processing Workflow
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state:
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "components/step-functions/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "step-functions"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  partition   = data.aws_partition.current.partition
  region      = data.aws_region.current.name
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# Lambda Functions for Workflow Tasks
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lambda" {
  name = "${local.name_prefix}-sfn-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-sfn-lambda-role"
  }
}

resource "aws_iam_role_policy" "lambda" {
  name = "${local.name_prefix}-sfn-lambda-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${local.partition}:logs:*:${local.account_id}:log-group:/aws/lambda/${local.name_prefix}-*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = "arn:${local.partition}:dynamodb:${local.region}:${local.account_id}:table/${local.name_prefix}-*"
      }
    ]
  })
}

# Validate Order Lambda
data "archive_file" "validate_order" {
  type        = "zip"
  output_path = "${path.module}/lambda/validate_order.zip"

  source {
    content  = <<-PYTHON
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """Validate the incoming order."""
    logger.info("Validating order: %s", json.dumps(event))

    order_id = event.get('order_id')
    items = event.get('items', [])
    customer_id = event.get('customer_id')

    if not order_id:
        return {'status': 'FAILED', 'error': 'Missing order_id'}
    if not items:
        return {'status': 'FAILED', 'error': 'No items in order'}
    if not customer_id:
        return {'status': 'FAILED', 'error': 'Missing customer_id'}

    total = sum(item.get('price', 0) * item.get('quantity', 0) for item in items)

    return {
        'status': 'VALIDATED',
        'order_id': order_id,
        'customer_id': customer_id,
        'items': items,
        'total_amount': total
    }
PYTHON
    filename = "validate_order.py"
  }
}

resource "aws_lambda_function" "validate_order" {
  function_name    = "${local.name_prefix}-validate-order"
  role             = aws_iam_role.lambda.arn
  handler          = "validate_order.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128
  filename         = data.archive_file.validate_order.output_path
  source_code_hash = data.archive_file.validate_order.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = {
    Name = "${local.name_prefix}-validate-order"
  }
}

# Process Payment Lambda
data "archive_file" "process_payment" {
  type        = "zip"
  output_path = "${path.module}/lambda/process_payment.zip"

  source {
    content  = <<-PYTHON
import json
import logging
import uuid

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """Process payment for the order."""
    logger.info("Processing payment: %s", json.dumps(event))

    order_id = event.get('order_id')
    total_amount = event.get('total_amount', 0)
    customer_id = event.get('customer_id')

    if total_amount <= 0:
        return {
            'status': 'PAYMENT_FAILED',
            'order_id': order_id,
            'error': 'Invalid payment amount'
        }

    transaction_id = str(uuid.uuid4())

    return {
        'status': 'PAYMENT_SUCCESS',
        'order_id': order_id,
        'customer_id': customer_id,
        'transaction_id': transaction_id,
        'total_amount': total_amount,
        'items': event.get('items', [])
    }
PYTHON
    filename = "process_payment.py"
  }
}

resource "aws_lambda_function" "process_payment" {
  function_name    = "${local.name_prefix}-process-payment"
  role             = aws_iam_role.lambda.arn
  handler          = "process_payment.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128
  filename         = data.archive_file.process_payment.output_path
  source_code_hash = data.archive_file.process_payment.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = {
    Name = "${local.name_prefix}-process-payment"
  }
}

# Update Inventory Lambda
data "archive_file" "update_inventory" {
  type        = "zip"
  output_path = "${path.module}/lambda/update_inventory.zip"

  source {
    content  = <<-PYTHON
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """Update inventory after successful payment."""
    logger.info("Updating inventory: %s", json.dumps(event))

    order_id = event.get('order_id')
    items = event.get('items', [])

    updated_items = []
    for item in items:
        updated_items.append({
            'item_id': item.get('item_id'),
            'quantity_reserved': item.get('quantity', 0),
            'status': 'RESERVED'
        })

    return {
        'status': 'INVENTORY_UPDATED',
        'order_id': order_id,
        'customer_id': event.get('customer_id'),
        'transaction_id': event.get('transaction_id'),
        'total_amount': event.get('total_amount'),
        'updated_items': updated_items
    }
PYTHON
    filename = "update_inventory.py"
  }
}

resource "aws_lambda_function" "update_inventory" {
  function_name    = "${local.name_prefix}-update-inventory"
  role             = aws_iam_role.lambda.arn
  handler          = "update_inventory.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128
  filename         = data.archive_file.update_inventory.output_path
  source_code_hash = data.archive_file.update_inventory.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = {
    Name = "${local.name_prefix}-update-inventory"
  }
}

# Send Notification Lambda
data "archive_file" "send_notification" {
  type        = "zip"
  output_path = "${path.module}/lambda/send_notification.zip"

  source {
    content  = <<-PYTHON
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """Send notification about order status."""
    logger.info("Sending notification: %s", json.dumps(event))

    order_id = event.get('order_id')
    customer_id = event.get('customer_id')
    status = event.get('status', 'UNKNOWN')

    notification = {
        'order_id': order_id,
        'customer_id': customer_id,
        'message': f'Order {order_id} has been processed successfully.',
        'notification_status': 'SENT',
        'final_status': 'ORDER_COMPLETE'
    }

    logger.info("Notification sent: %s", json.dumps(notification))
    return notification
PYTHON
    filename = "send_notification.py"
  }
}

resource "aws_lambda_function" "send_notification" {
  function_name    = "${local.name_prefix}-send-notification"
  role             = aws_iam_role.lambda.arn
  handler          = "send_notification.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128
  filename         = data.archive_file.send_notification.output_path
  source_code_hash = data.archive_file.send_notification.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  tags = {
    Name = "${local.name_prefix}-send-notification"
  }
}

# Lambda log groups
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = toset([
    aws_lambda_function.validate_order.function_name,
    aws_lambda_function.process_payment.function_name,
    aws_lambda_function.update_inventory.function_name,
    aws_lambda_function.send_notification.function_name,
  ])

  name              = "/aws/lambda/${each.value}"
  retention_in_days = 14

  tags = {
    Name = each.value
  }
}

# -----------------------------------------------------------------------------
# Step Functions IAM Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "step_functions" {
  name = "${local.name_prefix}-sfn-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-sfn-execution-role"
  }
}

resource "aws_iam_role_policy" "step_functions" {
  name = "${local.name_prefix}-sfn-execution-policy"
  role = aws_iam_role.step_functions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = [
          aws_lambda_function.validate_order.arn,
          aws_lambda_function.process_payment.arn,
          aws_lambda_function.update_inventory.arn,
          aws_lambda_function.send_notification.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogDelivery",
          "logs:CreateLogStream",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutLogEvents",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group for Step Functions
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "step_functions" {
  name              = "/aws/states/${local.name_prefix}-order-processing"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${local.name_prefix}-sfn-logs"
  }
}

# -----------------------------------------------------------------------------
# Step Functions State Machine - Order Processing
# -----------------------------------------------------------------------------

resource "aws_sfn_state_machine" "order_processing" {
  name     = "${local.name_prefix}-order-processing"
  role_arn = aws_iam_role.step_functions.arn

  definition = jsonencode({
    Comment = "Order processing workflow for ${var.project_name}"
    StartAt = "ValidateOrder"
    States = {
      ValidateOrder = {
        Type     = "Task"
        Resource = "arn:${local.partition}:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.validate_order.arn
          "Payload.$"  = "$"
        }
        ResultPath   = "$.validation"
        ResultSelector = {
          "status.$"       = "$.Payload.status"
          "order_id.$"     = "$.Payload.order_id"
          "customer_id.$"  = "$.Payload.customer_id"
          "items.$"        = "$.Payload.items"
          "total_amount.$" = "$.Payload.total_amount"
          "error.$"        = "$.Payload.error"
        }
        Retry = [
          {
            ErrorEquals     = ["Lambda.ServiceException", "Lambda.AWSLambdaException", "Lambda.SdkClientException"]
            IntervalSeconds = 2
            MaxAttempts     = 3
            BackoffRate     = 2
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "OrderFailed"
            ResultPath  = "$.error"
          }
        ]
        Next = "CheckValidation"
      }

      CheckValidation = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.validation.status"
            StringEquals = "VALIDATED"
            Next         = "ProcessPayment"
          }
        ]
        Default = "OrderFailed"
      }

      ProcessPayment = {
        Type     = "Task"
        Resource = "arn:${local.partition}:states:::lambda:invoke"
        Parameters = {
          FunctionName = aws_lambda_function.process_payment.arn
          Payload = {
            "order_id.$"     = "$.validation.order_id"
            "customer_id.$"  = "$.validation.customer_id"
            "items.$"        = "$.validation.items"
            "total_amount.$" = "$.validation.total_amount"
          }
        }
        ResultPath = "$.payment"
        ResultSelector = {
          "status.$"         = "$.Payload.status"
          "transaction_id.$" = "$.Payload.transaction_id"
          "total_amount.$"   = "$.Payload.total_amount"
          "items.$"          = "$.Payload.items"
        }
        Retry = [
          {
            ErrorEquals     = ["Lambda.ServiceException", "Lambda.AWSLambdaException"]
            IntervalSeconds = 5
            MaxAttempts     = 2
            BackoffRate     = 2
          }
        ]
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "PaymentFailed"
            ResultPath  = "$.error"
          }
        ]
        Next = "CheckPayment"
      }

      CheckPayment = {
        Type = "Choice"
        Choices = [
          {
            Variable     = "$.payment.status"
            StringEquals = "PAYMENT_SUCCESS"
            Next         = "ParallelPostPayment"
          }
        ]
        Default = "PaymentFailed"
      }

      ParallelPostPayment = {
        Type = "Parallel"
        Branches = [
          {
            StartAt = "UpdateInventory"
            States = {
              UpdateInventory = {
                Type     = "Task"
                Resource = "arn:${local.partition}:states:::lambda:invoke"
                Parameters = {
                  FunctionName = aws_lambda_function.update_inventory.arn
                  Payload = {
                    "order_id.$"       = "$.validation.order_id"
                    "customer_id.$"    = "$.validation.customer_id"
                    "items.$"          = "$.payment.items"
                    "transaction_id.$" = "$.payment.transaction_id"
                    "total_amount.$"   = "$.payment.total_amount"
                  }
                }
                ResultSelector = {
                  "status.$" = "$.Payload.status"
                }
                End = true
              }
            }
          },
          {
            StartAt = "SendConfirmation"
            States = {
              SendConfirmation = {
                Type     = "Task"
                Resource = "arn:${local.partition}:states:::lambda:invoke"
                Parameters = {
                  FunctionName = aws_lambda_function.send_notification.arn
                  Payload = {
                    "order_id.$"    = "$.validation.order_id"
                    "customer_id.$" = "$.validation.customer_id"
                    "status"        = "ORDER_CONFIRMED"
                  }
                }
                ResultSelector = {
                  "notification_status.$" = "$.Payload.notification_status"
                }
                End = true
              }
            }
          }
        ]
        ResultPath = "$.post_payment"
        Catch = [
          {
            ErrorEquals = ["States.ALL"]
            Next        = "OrderFailed"
            ResultPath  = "$.error"
          }
        ]
        Next = "WaitForShipping"
      }

      WaitForShipping = {
        Type    = "Wait"
        Seconds = 5
        Next    = "OrderComplete"
      }

      OrderComplete = {
        Type = "Succeed"
      }

      PaymentFailed = {
        Type  = "Fail"
        Error = "PaymentError"
        Cause = "Payment processing failed"
      }

      OrderFailed = {
        Type  = "Fail"
        Error = "OrderError"
        Cause = "Order processing failed"
      }
    }
  })

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.step_functions.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  tracing_configuration {
    enabled = true
  }

  tags = {
    Name = "${local.name_prefix}-order-processing"
  }
}
