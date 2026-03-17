# CloudWatch Alarms Module

Terraform module to create and manage AWS CloudWatch metric alarms and composite alarms with configurable notifications.

## Features

- Configurable list of metric alarms with full parameter support
- Composite alarm support with alarm rule expressions
- Default SNS topic for notifications across all alarms
- Per-alarm action overrides for ALARM, OK, and INSUFFICIENT_DATA states
- Treat missing data configuration
- Consistent naming and tagging

## Usage

```hcl
module "cloudwatch_alarms" {
  source = "../../modules/monitoring/cloudwatch-alarms"

  project     = "myapp"
  environment = "prod"

  default_sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:alerts"

  metric_alarms = [
    {
      alarm_name          = "high-cpu"
      namespace           = "AWS/EC2"
      metric_name         = "CPUUtilization"
      statistic           = "Average"
      period              = 300
      threshold           = 80
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 2
      treat_missing_data  = "missing"
      dimensions = {
        InstanceId = "i-0123456789abcdef0"
      }
    }
  ]

  composite_alarms = [
    {
      alarm_name  = "critical-composite"
      alarm_rule  = "ALARM(\"myapp-prod-high-cpu\")"
    }
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| metric_alarms | List of metric alarm configurations | list(object) | [] | no |
| composite_alarms | List of composite alarm configurations | list(object) | [] | no |
| default_sns_topic_arn | Default SNS topic ARN for notifications | string | "" | no |
| default_alarm_actions | Default ALARM action ARNs | list(string) | [] | no |
| default_ok_actions | Default OK action ARNs | list(string) | [] | no |

## Outputs

| Name | Description |
|------|-------------|
| metric_alarm_arns | Map of alarm names to ARNs |
| metric_alarm_ids | Map of alarm names to IDs |
| composite_alarm_arns | Map of composite alarm names to ARNs |
| composite_alarm_ids | Map of composite alarm names to IDs |
