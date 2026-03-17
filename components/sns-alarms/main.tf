# -----------------------------------------------------------------------------
# SNS Alarms Component - Topics, Subscriptions, CloudWatch Alarm Forwarding
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
  #   key            = "components/sns-alarms/terraform.tfstate"
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
      Component   = "sns-alarms"
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
# KMS Key for SNS Encryption
# -----------------------------------------------------------------------------

resource "aws_kms_key" "sns" {
  description             = "${local.name_prefix} SNS topic encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowSNSAccess"
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchAccess"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-sns-kms"
  }
}

resource "aws_kms_alias" "sns" {
  name          = "alias/${local.name_prefix}-sns"
  target_key_id = aws_kms_key.sns.key_id
}

# -----------------------------------------------------------------------------
# Critical Alerts SNS Topic
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "critical" {
  name              = "${local.name_prefix}-critical-alerts"
  kms_master_key_id = aws_kms_key.sns.id
  display_name      = "${var.project_name} Critical Alerts"

  tags = {
    Name     = "${local.name_prefix}-critical-alerts"
    Severity = "critical"
  }
}

resource "aws_sns_topic_policy" "critical" {
  arn = aws_sns_topic.critical.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.critical.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      },
      {
        Sid    = "AllowAccountPublish"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action = [
          "SNS:Publish",
          "SNS:Subscribe",
          "SNS:Receive"
        ]
        Resource = aws_sns_topic.critical.arn
      },
      {
        Sid    = "DenyNonSSL"
        Effect = "Deny"
        Principal = "*"
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.critical.arn
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# Email subscriptions for critical alerts
resource "aws_sns_topic_subscription" "critical_email" {
  for_each = toset(var.critical_email_endpoints)

  topic_arn = aws_sns_topic.critical.arn
  protocol  = "email"
  endpoint  = each.value
}

# -----------------------------------------------------------------------------
# Warning Alerts SNS Topic
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "warning" {
  name              = "${local.name_prefix}-warning-alerts"
  kms_master_key_id = aws_kms_key.sns.id
  display_name      = "${var.project_name} Warning Alerts"

  tags = {
    Name     = "${local.name_prefix}-warning-alerts"
    Severity = "warning"
  }
}

resource "aws_sns_topic_policy" "warning" {
  arn = aws_sns_topic.warning.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.warning.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      },
      {
        Sid    = "AllowAccountPublish"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action = [
          "SNS:Publish",
          "SNS:Subscribe",
          "SNS:Receive"
        ]
        Resource = aws_sns_topic.warning.arn
      }
    ]
  })
}

resource "aws_sns_topic_subscription" "warning_email" {
  for_each = toset(var.warning_email_endpoints)

  topic_arn = aws_sns_topic.warning.arn
  protocol  = "email"
  endpoint  = each.value
}

# -----------------------------------------------------------------------------
# Info / Operational SNS Topic
# -----------------------------------------------------------------------------

resource "aws_sns_topic" "info" {
  name              = "${local.name_prefix}-info-alerts"
  kms_master_key_id = aws_kms_key.sns.id
  display_name      = "${var.project_name} Info Alerts"

  tags = {
    Name     = "${local.name_prefix}-info-alerts"
    Severity = "info"
  }
}

resource "aws_sns_topic_policy" "info" {
  arn = aws_sns_topic.info.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchPublish"
        Effect = "Allow"
        Principal = {
          Service = "cloudwatch.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.info.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      },
      {
        Sid    = "AllowAccountPublish"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action = [
          "SNS:Publish",
          "SNS:Subscribe",
          "SNS:Receive"
        ]
        Resource = aws_sns_topic.info.arn
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Lambda for Alarm Processing / Notification Enrichment
# -----------------------------------------------------------------------------

resource "aws_iam_role" "alarm_processor" {
  name = "${local.name_prefix}-alarm-processor-role"

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
    Name = "${local.name_prefix}-alarm-processor-role"
  }
}

resource "aws_iam_role_policy" "alarm_processor" {
  name = "${local.name_prefix}-alarm-processor-policy"
  role = aws_iam_role.alarm_processor.id

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
          "sns:Publish"
        ]
        Resource = [
          aws_sns_topic.critical.arn,
          aws_sns_topic.warning.arn,
          aws_sns_topic.info.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarms",
          "cloudwatch:GetMetricData"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.sns.arn
      }
    ]
  })
}

data "archive_file" "alarm_processor" {
  type        = "zip"
  output_path = "${path.module}/lambda/alarm_processor.zip"

  source {
    content  = <<-PYTHON
import json
import os
import logging
import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sns_client = boto3.client('sns')

def handler(event, context):
    """
    Process SNS alarm notifications and enrich them with context.
    Forwards enriched messages to the appropriate severity topic.
    """
    logger.info("Received event: %s", json.dumps(event))

    for record in event.get('Records', []):
        sns_message = record.get('Sns', {})
        subject = sns_message.get('Subject', 'No Subject')
        message_body = sns_message.get('Message', '{}')

        try:
            alarm_data = json.loads(message_body)
        except json.JSONDecodeError:
            alarm_data = {"raw_message": message_body}

        alarm_name = alarm_data.get('AlarmName', 'Unknown')
        new_state = alarm_data.get('NewStateValue', 'UNKNOWN')
        reason = alarm_data.get('NewStateReason', 'No reason provided')
        timestamp = alarm_data.get('StateChangeTime', 'Unknown')

        enriched_message = {
            "alarm_name": alarm_name,
            "state": new_state,
            "reason": reason,
            "timestamp": timestamp,
            "account_id": alarm_data.get('AWSAccountId', 'Unknown'),
            "region": alarm_data.get('Region', 'Unknown'),
            "environment": os.environ.get('ENVIRONMENT', 'unknown'),
            "project": os.environ.get('PROJECT_NAME', 'unknown')
        }

        logger.info("Processed alarm: %s -> %s", alarm_name, new_state)

        return {
            'statusCode': 200,
            'body': json.dumps(enriched_message)
        }

    return {'statusCode': 200, 'body': 'No records to process'}
PYTHON
    filename = "alarm_processor.py"
  }
}

resource "aws_lambda_function" "alarm_processor" {
  function_name    = "${local.name_prefix}-alarm-processor"
  role             = aws_iam_role.alarm_processor.arn
  handler          = "alarm_processor.handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 128
  filename         = data.archive_file.alarm_processor.output_path
  source_code_hash = data.archive_file.alarm_processor.output_base64sha256

  environment {
    variables = {
      PROJECT_NAME = var.project_name
      ENVIRONMENT  = var.environment
    }
  }

  tags = {
    Name = "${local.name_prefix}-alarm-processor"
  }
}

resource "aws_cloudwatch_log_group" "alarm_processor" {
  name              = "/aws/lambda/${aws_lambda_function.alarm_processor.function_name}"
  retention_in_days = 14

  tags = {
    Name = "${local.name_prefix}-alarm-processor-logs"
  }
}

resource "aws_lambda_permission" "sns_critical" {
  statement_id  = "AllowSNSCriticalInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alarm_processor.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.critical.arn
}

resource "aws_sns_topic_subscription" "critical_lambda" {
  topic_arn = aws_sns_topic.critical.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alarm_processor.arn
}

# -----------------------------------------------------------------------------
# Example CloudWatch Alarms that forward to SNS
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_critical" {
  alarm_name          = "${local.name_prefix}-ec2-cpu-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  alarm_description   = "EC2 CPU utilization is critically high (>90%)"
  treat_missing_data  = "breaching"

  alarm_actions = [aws_sns_topic.critical.arn]
  ok_actions    = [aws_sns_topic.info.arn]

  tags = {
    Name     = "${local.name_prefix}-ec2-cpu-critical"
    Severity = "critical"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_cpu_warning" {
  alarm_name          = "${local.name_prefix}-ec2-cpu-warning"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "EC2 CPU utilization is high (>75%)"
  treat_missing_data  = "missing"

  alarm_actions = [aws_sns_topic.warning.arn]
  ok_actions    = [aws_sns_topic.info.arn]

  tags = {
    Name     = "${local.name_prefix}-ec2-cpu-warning"
    Severity = "warning"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_connections" {
  alarm_name          = "${local.name_prefix}-rds-connections-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.rds_connections_threshold
  alarm_description   = "RDS database connections exceeded threshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.warning.arn]
  ok_actions    = [aws_sns_topic.info.arn]

  tags = {
    Name     = "${local.name_prefix}-rds-connections"
    Severity = "warning"
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${local.name_prefix}-alb-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = var.alb_5xx_threshold
  alarm_description   = "ALB 5xx error count exceeded threshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.critical.arn]
  ok_actions    = [aws_sns_topic.info.arn]

  tags = {
    Name     = "${local.name_prefix}-alb-5xx"
    Severity = "critical"
  }
}
