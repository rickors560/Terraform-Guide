# Monitoring Modules

Terraform modules for AWS observability and auditing including CloudWatch metrics, logs, dashboards, alarms, SNS notifications, and CloudTrail.

## Sub-Modules

| Module | Description |
|--------|-------------|
| [cloudwatch-logs](./cloudwatch-logs/) | CloudWatch Log Groups with metric filters and subscription filters |
| [cloudwatch-alarms](./cloudwatch-alarms/) | CloudWatch metric alarms and composite alarms with configurable notifications |
| [cloudwatch-dashboard](./cloudwatch-dashboard/) | CloudWatch Dashboards with configurable widgets or raw JSON body |
| [sns-topic](./sns-topic/) | SNS Topics with subscriptions, encryption, and access policies |
| [cloudtrail](./cloudtrail/) | CloudTrail with S3 bucket, CloudWatch Logs integration, encryption, and event selectors |

## How They Relate

```
cloudwatch-logs --> cloudwatch-alarms --> sns-topic --> Email/Slack/PagerDuty
                         |
                         v
                  cloudwatch-dashboard (visualizes metrics and alarm states)

cloudtrail --> cloudwatch-logs (API activity audit trail)
```

- **cloudwatch-logs** collects log data from services (Lambda, ECS, EKS, VPC flow logs). Metric filters extract numeric values from logs.
- **cloudwatch-alarms** monitors metrics (including those from log metric filters) and triggers actions when thresholds are breached.
- **sns-topic** receives alarm notifications and fans them out to subscribers (email, Lambda, HTTPS endpoints).
- **cloudwatch-dashboard** provides at-a-glance visibility into metrics and alarm states.
- **cloudtrail** captures AWS API activity and delivers events to S3 and optionally to CloudWatch Logs for monitoring.

## Usage Example

```hcl
module "sns_alerts" {
  source = "../../modules/monitoring/sns-topic"

  project     = "myapp"
  environment = "prod"
  name_suffix = "alerts"

  subscriptions = [
    { protocol = "email", endpoint = "oncall@example.com" }
  ]

  team = "platform"
}

module "app_logs" {
  source = "../../modules/monitoring/cloudwatch-logs"

  project     = "myapp"
  environment = "prod"
  name_suffix = "app"

  retention_in_days = 30

  metric_filters = [
    {
      name    = "error-count"
      pattern = "ERROR"
      metric_transformation = {
        name      = "AppErrorCount"
        namespace = "myapp/prod"
        value     = "1"
      }
    }
  ]

  team = "platform"
}

module "alarms" {
  source = "../../modules/monitoring/cloudwatch-alarms"

  project     = "myapp"
  environment = "prod"

  default_sns_topic_arn = module.sns_alerts.topic_arn

  metric_alarms = [
    {
      alarm_name          = "high-error-rate"
      namespace           = "myapp/prod"
      metric_name         = "AppErrorCount"
      statistic           = "Sum"
      period              = 300
      threshold           = 10
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 2
      treat_missing_data  = "notBreaching"
    }
  ]

  team = "platform"
}

module "dashboard" {
  source = "../../modules/monitoring/cloudwatch-dashboard"

  project     = "myapp"
  environment = "prod"
  name_suffix = "overview"

  widgets = [
    {
      type   = "metric"
      title  = "Application Errors"
      metrics = [["myapp/prod", "AppErrorCount"]]
      period = 300
      stat   = "Sum"
    }
  ]

  team = "platform"
}

module "trail" {
  source = "../../modules/monitoring/cloudtrail"

  project     = "myapp"
  environment = "prod"

  s3_bucket_name        = module.trail_bucket.bucket_name
  enable_log_file_validation = true
  is_multi_region_trail = true

  team = "platform"
}
```
