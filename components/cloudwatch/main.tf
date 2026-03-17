# -----------------------------------------------------------------------------
# CloudWatch Component - Dashboard, Alarms, Log Groups, Metric Filters
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
  #   key            = "components/cloudwatch/terraform.tfstate"
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
      Component   = "cloudwatch"
    }
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# CloudWatch Log Groups
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "application" {
  name              = "/${var.project_name}/${var.environment}/application"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = {
    Name = "${local.name_prefix}-application-logs"
  }
}

resource "aws_cloudwatch_log_group" "access" {
  name              = "/${var.project_name}/${var.environment}/access"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = {
    Name = "${local.name_prefix}-access-logs"
  }
}

resource "aws_cloudwatch_log_group" "error" {
  name              = "/${var.project_name}/${var.environment}/error"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = {
    Name = "${local.name_prefix}-error-logs"
  }
}

# -----------------------------------------------------------------------------
# Metric Filters
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${local.name_prefix}-error-count"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "ERROR"

  metric_transformation {
    name          = "ErrorCount"
    namespace     = "${var.project_name}/${var.environment}"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "warning_count" {
  name           = "${local.name_prefix}-warning-count"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "WARN"

  metric_transformation {
    name          = "WarningCount"
    namespace     = "${var.project_name}/${var.environment}"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "http_5xx" {
  name           = "${local.name_prefix}-http-5xx"
  log_group_name = aws_cloudwatch_log_group.access.name
  pattern        = "[ip, id, user, timestamp, request, status_code = 5*, size]"

  metric_transformation {
    name          = "HTTP5xxCount"
    namespace     = "${var.project_name}/${var.environment}"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "http_4xx" {
  name           = "${local.name_prefix}-http-4xx"
  log_group_name = aws_cloudwatch_log_group.access.name
  pattern        = "[ip, id, user, timestamp, request, status_code = 4*, size]"

  metric_transformation {
    name          = "HTTP4xxCount"
    namespace     = "${var.project_name}/${var.environment}"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "latency_high" {
  name           = "${local.name_prefix}-latency-high"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "{ $.latency > 5000 }"

  metric_transformation {
    name          = "HighLatencyCount"
    namespace     = "${var.project_name}/${var.environment}"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Metric Alarms - EC2
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name_prefix}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold_high
  alarm_description   = "EC2 CPU utilization exceeded ${var.cpu_threshold_high}% for 15 minutes"
  treat_missing_data  = "breaching"

  dimensions = var.ec2_instance_id != "" ? {
    InstanceId = var.ec2_instance_id
  } : {}

  alarm_actions = var.alarm_sns_topic_arns
  ok_actions    = var.alarm_sns_topic_arns

  tags = {
    Name     = "${local.name_prefix}-cpu-high"
    Severity = "warning"
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_critical" {
  alarm_name          = "${local.name_prefix}-cpu-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_threshold_critical
  alarm_description   = "EC2 CPU utilization exceeded ${var.cpu_threshold_critical}% for 10 minutes"
  treat_missing_data  = "breaching"

  dimensions = var.ec2_instance_id != "" ? {
    InstanceId = var.ec2_instance_id
  } : {}

  alarm_actions = var.alarm_sns_topic_arns
  ok_actions    = var.alarm_sns_topic_arns

  tags = {
    Name     = "${local.name_prefix}-cpu-critical"
    Severity = "critical"
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${local.name_prefix}-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = var.memory_threshold
  alarm_description   = "Memory utilization exceeded ${var.memory_threshold}%"
  treat_missing_data  = "missing"

  dimensions = var.ec2_instance_id != "" ? {
    InstanceId = var.ec2_instance_id
  } : {}

  alarm_actions = var.alarm_sns_topic_arns
  ok_actions    = var.alarm_sns_topic_arns

  tags = {
    Name     = "${local.name_prefix}-memory-high"
    Severity = "warning"
  }
}

resource "aws_cloudwatch_metric_alarm" "disk_high" {
  alarm_name          = "${local.name_prefix}-disk-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "disk_used_percent"
  namespace           = "CWAgent"
  period              = 300
  statistic           = "Average"
  threshold           = var.disk_threshold
  alarm_description   = "Disk utilization exceeded ${var.disk_threshold}%"
  treat_missing_data  = "missing"

  dimensions = var.ec2_instance_id != "" ? {
    InstanceId  = var.ec2_instance_id
    path        = "/"
    device      = "xvda1"
    fstype      = "ext4"
  } : {}

  alarm_actions = var.alarm_sns_topic_arns
  ok_actions    = var.alarm_sns_topic_arns

  tags = {
    Name     = "${local.name_prefix}-disk-high"
    Severity = "warning"
  }
}

# -----------------------------------------------------------------------------
# Application Error Alarms
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "${local.name_prefix}-error-rate-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ErrorCount"
  namespace           = "${var.project_name}/${var.environment}"
  period              = 300
  statistic           = "Sum"
  threshold           = var.error_rate_threshold
  alarm_description   = "Application error count exceeded ${var.error_rate_threshold} in 5 minutes"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_sns_topic_arns
  ok_actions    = var.alarm_sns_topic_arns

  tags = {
    Name     = "${local.name_prefix}-error-rate"
    Severity = "warning"
  }
}

resource "aws_cloudwatch_metric_alarm" "http_5xx_rate" {
  alarm_name          = "${local.name_prefix}-http-5xx-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTP5xxCount"
  namespace           = "${var.project_name}/${var.environment}"
  period              = 300
  statistic           = "Sum"
  threshold           = var.http_5xx_threshold
  alarm_description   = "HTTP 5xx error count exceeded ${var.http_5xx_threshold} in 5 minutes"
  treat_missing_data  = "notBreaching"

  alarm_actions = var.alarm_sns_topic_arns
  ok_actions    = var.alarm_sns_topic_arns

  tags = {
    Name     = "${local.name_prefix}-http-5xx"
    Severity = "critical"
  }
}

# -----------------------------------------------------------------------------
# Composite Alarm
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_composite_alarm" "system_health" {
  alarm_name        = "${local.name_prefix}-system-health"
  alarm_description = "Composite alarm: triggers when CPU is critical AND error rate is high"

  alarm_rule = "ALARM(\"${aws_cloudwatch_metric_alarm.cpu_critical.alarm_name}\") AND ALARM(\"${aws_cloudwatch_metric_alarm.error_rate.alarm_name}\")"

  alarm_actions             = var.alarm_sns_topic_arns
  ok_actions                = var.alarm_sns_topic_arns
  insufficient_data_actions = []

  tags = {
    Name     = "${local.name_prefix}-system-health"
    Severity = "critical"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Dashboard
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${local.name_prefix}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 1
        properties = {
          markdown = "# ${var.project_name} - ${var.environment} Dashboard"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 1
        width  = 12
        height = 6
        properties = {
          title  = "CPU Utilization"
          view   = "timeSeries"
          region = var.region
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", period = 300 }]
          ]
          yAxis = {
            left = { min = 0, max = 100 }
          }
          annotations = {
            horizontal = [
              { label = "Warning", value = var.cpu_threshold_high, color = "#ff9900" },
              { label = "Critical", value = var.cpu_threshold_critical, color = "#d13212" }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 1
        width  = 12
        height = 6
        properties = {
          title  = "Memory Utilization"
          view   = "timeSeries"
          region = var.region
          metrics = [
            ["CWAgent", "mem_used_percent", { stat = "Average", period = 300 }]
          ]
          yAxis = {
            left = { min = 0, max = 100 }
          }
          annotations = {
            horizontal = [
              { label = "Threshold", value = var.memory_threshold, color = "#ff9900" }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 7
        width  = 12
        height = 6
        properties = {
          title  = "Disk Utilization"
          view   = "timeSeries"
          region = var.region
          metrics = [
            ["CWAgent", "disk_used_percent", { stat = "Average", period = 300 }]
          ]
          yAxis = {
            left = { min = 0, max = 100 }
          }
          annotations = {
            horizontal = [
              { label = "Threshold", value = var.disk_threshold, color = "#ff9900" }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 7
        width  = 12
        height = 6
        properties = {
          title  = "Network Traffic"
          view   = "timeSeries"
          region = var.region
          metrics = [
            ["AWS/EC2", "NetworkIn", { stat = "Average", period = 300, label = "Bytes In" }],
            ["AWS/EC2", "NetworkOut", { stat = "Average", period = 300, label = "Bytes Out" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 13
        width  = 8
        height = 6
        properties = {
          title  = "Application Errors"
          view   = "timeSeries"
          region = var.region
          metrics = [
            ["${var.project_name}/${var.environment}", "ErrorCount", { stat = "Sum", period = 300, color = "#d13212" }],
            ["${var.project_name}/${var.environment}", "WarningCount", { stat = "Sum", period = 300, color = "#ff9900" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 13
        width  = 8
        height = 6
        properties = {
          title  = "HTTP Status Codes"
          view   = "timeSeries"
          region = var.region
          metrics = [
            ["${var.project_name}/${var.environment}", "HTTP5xxCount", { stat = "Sum", period = 300, color = "#d13212", label = "5xx" }],
            ["${var.project_name}/${var.environment}", "HTTP4xxCount", { stat = "Sum", period = 300, color = "#ff9900", label = "4xx" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 13
        width  = 8
        height = 6
        properties = {
          title  = "High Latency Events"
          view   = "timeSeries"
          region = var.region
          metrics = [
            ["${var.project_name}/${var.environment}", "HighLatencyCount", { stat = "Sum", period = 300, color = "#ff9900" }]
          ]
        }
      },
      {
        type   = "alarm"
        x      = 0
        y      = 19
        width  = 24
        height = 3
        properties = {
          title  = "Alarm Status"
          alarms = [
            aws_cloudwatch_metric_alarm.cpu_high.arn,
            aws_cloudwatch_metric_alarm.cpu_critical.arn,
            aws_cloudwatch_metric_alarm.memory_high.arn,
            aws_cloudwatch_metric_alarm.disk_high.arn,
            aws_cloudwatch_metric_alarm.error_rate.arn,
            aws_cloudwatch_metric_alarm.http_5xx_rate.arn,
            aws_cloudwatch_composite_alarm.system_health.arn
          ]
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 22
        width  = 24
        height = 6
        properties = {
          title  = "Recent Error Logs"
          region = var.region
          query  = "SOURCE '${aws_cloudwatch_log_group.application.name}' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 20"
          view   = "table"
        }
      }
    ]
  })
}
