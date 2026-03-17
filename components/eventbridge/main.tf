###############################################################################
# EventBridge Component — Rules with Custom Event Pattern, Targets, DLQ
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
  #   key            = "components/eventbridge/terraform.tfstate"
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
      Component   = "eventbridge"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Custom Event Bus
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_bus" "main" {
  name = "${var.project_name}-${var.environment}-events"

  tags = {
    Name = "${var.project_name}-${var.environment}-events"
  }
}

resource "aws_cloudwatch_event_bus_policy" "main" {
  event_bus_name = aws_cloudwatch_event_bus.main.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAccountAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "events:PutEvents"
        Resource  = aws_cloudwatch_event_bus.main.arn
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# DLQ for Failed Event Deliveries
# -----------------------------------------------------------------------------

resource "aws_sqs_queue" "event_dlq" {
  name                       = "${var.project_name}-${var.environment}-events-dlq"
  message_retention_seconds  = 1209600
  sqs_managed_sse_enabled    = true
  receive_wait_time_seconds  = 20

  tags = {
    Name = "${var.project_name}-${var.environment}-events-dlq"
  }
}

resource "aws_sqs_queue_policy" "event_dlq" {
  queue_url = aws_sqs_queue.event_dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowEventBridgeDLQ"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.event_dlq.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = [
              aws_cloudwatch_event_rule.custom_events.arn,
              aws_cloudwatch_event_rule.scheduled.arn,
            ]
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Lambda Target Function
# -----------------------------------------------------------------------------

data "archive_file" "event_handler" {
  type        = "zip"
  output_path = "${path.module}/event_handler.zip"

  source {
    content = <<-PYTHON
import json
import logging
from datetime import datetime

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def handler(event, context):
    """Process EventBridge events."""
    logger.info("Received event: %s", json.dumps(event))

    detail_type = event.get("detail-type", "Unknown")
    source = event.get("source", "unknown")
    detail = event.get("detail", {})

    logger.info(
        "Processing event: source=%s, detail-type=%s, detail=%s",
        source, detail_type, json.dumps(detail)
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "Event processed successfully",
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "source": source,
            "detail_type": detail_type,
        }),
    }
    PYTHON

    filename = "event_handler.py"
  }
}

resource "aws_iam_role" "event_handler" {
  name = "${var.project_name}-${var.environment}-event-handler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "event_handler_logs" {
  name = "cloudwatch-logs"
  role = aws_iam_role.event_handler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "${aws_cloudwatch_log_group.event_handler.arn}:*"
    }]
  })
}

resource "aws_cloudwatch_log_group" "event_handler" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-event-handler"
  retention_in_days = 30
}

resource "aws_lambda_function" "event_handler" {
  function_name    = "${var.project_name}-${var.environment}-event-handler"
  description      = "EventBridge event handler"
  filename         = data.archive_file.event_handler.output_path
  source_code_hash = data.archive_file.event_handler.output_base64sha256
  handler          = "event_handler.handler"
  runtime          = "python3.12"
  role             = aws_iam_role.event_handler.arn
  memory_size      = 128
  timeout          = 60

  environment {
    variables = {
      ENVIRONMENT  = var.environment
      PROJECT_NAME = var.project_name
    }
  }

  depends_on = [aws_cloudwatch_log_group.event_handler]

  tags = {
    Name = "${var.project_name}-${var.environment}-event-handler"
  }
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.event_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.custom_events.arn
}

resource "aws_lambda_permission" "eventbridge_scheduled" {
  statement_id  = "AllowEventBridgeScheduledInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.event_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scheduled.arn
}

# -----------------------------------------------------------------------------
# SQS Target Queue
# -----------------------------------------------------------------------------

resource "aws_sqs_queue" "event_target" {
  name                       = "${var.project_name}-${var.environment}-event-queue"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600
  sqs_managed_sse_enabled    = true
  receive_wait_time_seconds  = 20

  tags = {
    Name = "${var.project_name}-${var.environment}-event-queue"
  }
}

resource "aws_sqs_queue_policy" "event_target" {
  queue_url = aws_sqs_queue.event_target.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowEventBridgeSend"
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.event_target.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = aws_cloudwatch_event_rule.custom_events.arn
        }
      }
    }]
  })
}

# -----------------------------------------------------------------------------
# Rule 1: Custom Event Pattern
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "custom_events" {
  name           = "${var.project_name}-${var.environment}-custom-events"
  description    = "Capture custom application events"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source      = [var.event_source]
    detail-type = var.event_detail_types
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-custom-events"
  }
}

# Lambda target for custom events
resource "aws_cloudwatch_event_target" "custom_lambda" {
  rule           = aws_cloudwatch_event_rule.custom_events.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  target_id      = "lambda-target"
  arn            = aws_lambda_function.event_handler.arn

  dead_letter_config {
    arn = aws_sqs_queue.event_dlq.arn
  }

  retry_policy {
    maximum_event_age_in_seconds = 3600
    maximum_retry_attempts       = 3
  }
}

# SQS target for custom events
resource "aws_cloudwatch_event_target" "custom_sqs" {
  rule           = aws_cloudwatch_event_rule.custom_events.name
  event_bus_name = aws_cloudwatch_event_bus.main.name
  target_id      = "sqs-target"
  arn            = aws_sqs_queue.event_target.arn

  dead_letter_config {
    arn = aws_sqs_queue.event_dlq.arn
  }

  retry_policy {
    maximum_event_age_in_seconds = 3600
    maximum_retry_attempts       = 3
  }
}

# -----------------------------------------------------------------------------
# Rule 2: Scheduled Expression
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "scheduled" {
  name                = "${var.project_name}-${var.environment}-scheduled"
  description         = "Scheduled event (${var.schedule_expression})"
  schedule_expression = var.schedule_expression

  tags = {
    Name = "${var.project_name}-${var.environment}-scheduled"
  }
}

resource "aws_cloudwatch_event_target" "scheduled_lambda" {
  rule      = aws_cloudwatch_event_rule.scheduled.name
  target_id = "scheduled-lambda-target"
  arn       = aws_lambda_function.event_handler.arn

  dead_letter_config {
    arn = aws_sqs_queue.event_dlq.arn
  }

  input = jsonencode({
    source      = "aws.scheduler"
    detail-type = "ScheduledEvent"
    detail = {
      schedule = var.schedule_expression
    }
  })
}

# -----------------------------------------------------------------------------
# EventBridge Archive (event replay)
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_event_archive" "main" {
  name             = "${var.project_name}-${var.environment}-events-archive"
  event_source_arn = aws_cloudwatch_event_bus.main.arn
  description      = "Archive for ${var.project_name}-${var.environment} events"
  retention_days   = var.archive_retention_days

  event_pattern = jsonencode({
    source = [var.event_source]
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "failed_invocations" {
  alarm_name          = "${var.project_name}-${var.environment}-eventbridge-failed-invocations"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedInvocations"
  namespace           = "AWS/Events"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "EventBridge rule has failed invocations"
  treat_missing_data  = "notBreaching"

  dimensions = {
    RuleName = aws_cloudwatch_event_rule.custom_events.name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-eventbridge-failures-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${var.project_name}-${var.environment}-eventbridge-dlq-not-empty"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "EventBridge DLQ has messages"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.event_dlq.name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-eventbridge-dlq-alarm"
  }
}
