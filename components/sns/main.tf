###############################################################################
# SNS Component — Topic with Email/SQS Subscriptions, Encryption, Policies
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
  #   key            = "components/sns/terraform.tfstate"
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
      Component   = "sns"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# SNS Topic
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "main" {
  name         = var.fifo_topic ? "${var.project_name}-${var.environment}-${var.topic_name}.fifo" : "${var.project_name}-${var.environment}-${var.topic_name}"
  display_name = "${var.project_name} ${var.environment} ${var.topic_name}"

  fifo_topic                  = var.fifo_topic
  content_based_deduplication = var.fifo_topic

  kms_master_key_id = var.kms_key_arn != "" ? var.kms_key_arn : "alias/aws/sns"

  delivery_policy = jsonencode({
    http = {
      defaultHealthyRetryPolicy = {
        minDelayTarget     = 20
        maxDelayTarget     = 20
        numRetries         = 3
        numMaxDelayRetries = 0
        numNoDelayRetries  = 0
        numMinDelayRetries = 0
        backoffFunction    = "linear"
      }
      disableSubscriptionOverrides = false
    }
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-${var.topic_name}"
  }
}

# -----------------------------------------------------------------------------
# Topic Policy
# -----------------------------------------------------------------------------

resource "aws_sns_topic_policy" "main" {
  arn = aws_sns_topic.main.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowAccountPublish"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action = [
          "sns:Publish",
          "sns:Subscribe",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:ListSubscriptionsByTopic"
        ]
        Resource = aws_sns_topic.main.arn
      },
      {
        Sid       = "AllowCloudWatchAlarms"
        Effect    = "Allow"
        Principal = { Service = "cloudwatch.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.main.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid       = "AllowEventBridge"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.main.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.main.arn
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
# Email Subscriptions
# -----------------------------------------------------------------------------

resource "aws_sns_topic_subscription" "email" {
  for_each = toset(var.email_subscribers)

  topic_arn = aws_sns_topic.main.arn
  protocol  = "email"
  endpoint  = each.value
}

# -----------------------------------------------------------------------------
# SQS Subscriptions
# -----------------------------------------------------------------------------

resource "aws_sns_topic_subscription" "sqs" {
  for_each = toset(var.sqs_subscriber_arns)

  topic_arn            = aws_sns_topic.main.arn
  protocol             = "sqs"
  endpoint             = each.value
  raw_message_delivery = var.raw_message_delivery

  filter_policy_scope = var.filter_policy != "" ? "MessageBody" : null
  filter_policy       = var.filter_policy != "" ? var.filter_policy : null
}

# -----------------------------------------------------------------------------
# Lambda Subscriptions
# -----------------------------------------------------------------------------

resource "aws_sns_topic_subscription" "lambda" {
  for_each = toset(var.lambda_subscriber_arns)

  topic_arn = aws_sns_topic.main.arn
  protocol  = "lambda"
  endpoint  = each.value
}

# Allow SNS to invoke Lambda functions
resource "aws_lambda_permission" "sns" {
  for_each = toset(var.lambda_subscriber_arns)

  statement_id  = "AllowSNSInvoke-${md5(each.value)}"
  action        = "lambda:InvokeFunction"
  function_name = each.value
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.main.arn
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "failed_notifications" {
  alarm_name          = "${var.project_name}-${var.environment}-${var.topic_name}-failed-notifications"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfNotificationsFailed"
  namespace           = "AWS/SNS"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "SNS topic has failed notifications"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TopicName = aws_sns_topic.main.name
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-sns-failed-alarm"
  }
}
