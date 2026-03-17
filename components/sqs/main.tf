###############################################################################
# SQS Component — Queue with DLQ, Encryption, Access Policy, CloudWatch Alarms
###############################################################################

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "components/sqs/terraform.tfstate"
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
      Component   = "sqs"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Dead Letter Queue
# -----------------------------------------------------------------------------

resource "aws_sqs_queue" "dlq" {
  name = "${var.project_name}-${var.environment}-${var.queue_name}-dlq"

  message_retention_seconds  = 1209600 # 14 days (maximum)
  visibility_timeout_seconds = var.visibility_timeout_seconds
  receive_wait_time_seconds  = 20

  sqs_managed_sse_enabled = var.kms_key_arn == ""
  kms_master_key_id       = var.kms_key_arn != "" ? var.kms_key_arn : null
  kms_data_key_reuse_period_seconds = var.kms_key_arn != "" ? 300 : null

  tags = {
    Name = "${var.project_name}-${var.environment}-${var.queue_name}-dlq"
  }
}

resource "aws_sqs_queue_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonAccountAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sqs:*"
        Resource  = aws_sqs_queue.dlq.arn
        Condition = {
          StringNotEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sqs:*"
        Resource  = aws_sqs_queue.dlq.arn
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Main Queue
# -----------------------------------------------------------------------------

resource "aws_sqs_queue" "main" {
  name = var.fifo_queue ? "${var.project_name}-${var.environment}-${var.queue_name}.fifo" : "${var.project_name}-${var.environment}-${var.queue_name}"

  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size
  message_retention_seconds  = var.message_retention_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null
  deduplication_scope         = var.fifo_queue ? "messageGroup" : null
  fifo_throughput_limit       = var.fifo_queue ? "perMessageGroupId" : null

  sqs_managed_sse_enabled = var.kms_key_arn == ""
  kms_master_key_id       = var.kms_key_arn != "" ? var.kms_key_arn : null
  kms_data_key_reuse_period_seconds = var.kms_key_arn != "" ? 300 : null

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-${var.queue_name}"
  }
}

# -----------------------------------------------------------------------------
# Main Queue Policy
# -----------------------------------------------------------------------------

resource "aws_sqs_queue_policy" "main" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyNonAccountAccess"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sqs:*"
        Resource  = aws_sqs_queue.main.arn
        Condition = {
          StringNotEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sqs:*"
        Resource  = aws_sqs_queue.main.arn
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "AllowSNSPublish"
        Effect    = "Allow"
        Principal = { Service = "sns.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Resource  = aws_sqs_queue.main.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Redrive Allow Policy (allow main queue to send to DLQ)
# -----------------------------------------------------------------------------

resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.main.arn]
  })
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "queue_depth" {
  alarm_name          = "${var.project_name}-${var.environment}-${var.queue_name}-depth-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = var.queue_depth_alarm_threshold
  alarm_description   = "SQS queue depth exceeds threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.main.name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-sqs-depth-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${var.project_name}-${var.environment}-${var.queue_name}-dlq-not-empty"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Messages present in dead-letter queue"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-sqs-dlq-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "message_age" {
  alarm_name          = "${var.project_name}-${var.environment}-${var.queue_name}-age-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Maximum"
  threshold           = var.message_age_alarm_threshold
  alarm_description   = "Oldest message age exceeds threshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.main.name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-sqs-age-alarm"
  }
}
