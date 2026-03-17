provider "aws" {
  region = var.aws_region
}

module "sns_topic" {
  source = "../../../sns-topic"

  project     = var.project
  environment = var.environment

  name        = "alarms"
  display_name = "CloudWatch Alarm Notifications"

  subscriptions = [
    {
      protocol = "email"
      endpoint = var.notification_email
    }
  ]
}

module "cloudwatch_alarms" {
  source = "../../"

  project     = var.project
  environment = var.environment

  default_sns_topic_arn = module.sns_topic.topic_arn

  metric_alarms = [
    {
      alarm_name          = "high-cpu-utilization"
      alarm_description   = "CPU utilization exceeds 80% for 10 minutes"
      namespace           = "AWS/EC2"
      metric_name         = "CPUUtilization"
      statistic           = "Average"
      period              = 300
      threshold           = 80
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 2
      treat_missing_data  = "missing"
      dimensions = {
        InstanceId = var.instance_id
      }
    },
    {
      alarm_name          = "high-memory-utilization"
      alarm_description   = "Memory utilization exceeds 85%"
      namespace           = "CWAgent"
      metric_name         = "mem_used_percent"
      statistic           = "Average"
      period              = 300
      threshold           = 85
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 2
      treat_missing_data  = "missing"
      dimensions = {
        InstanceId = var.instance_id
      }
    },
    {
      alarm_name          = "status-check-failed"
      alarm_description   = "EC2 instance status check failed"
      namespace           = "AWS/EC2"
      metric_name         = "StatusCheckFailed"
      statistic           = "Maximum"
      period              = 60
      threshold           = 1
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 2
      treat_missing_data  = "breaching"
      dimensions = {
        InstanceId = var.instance_id
      }
    },
  ]

  composite_alarms = [
    {
      alarm_name        = "critical-instance-health"
      alarm_description = "Instance has high CPU AND status check failure"
      alarm_rule        = "ALARM(\"${var.project}-${var.environment}-high-cpu-utilization\") AND ALARM(\"${var.project}-${var.environment}-status-check-failed\")"
    }
  ]

  additional_tags = {
    Example = "complete"
  }
}
