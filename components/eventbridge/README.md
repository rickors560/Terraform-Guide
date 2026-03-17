# EventBridge Component

Production-grade EventBridge setup with custom event bus, event pattern rules, scheduled rules, Lambda/SQS targets, DLQ, and event archiving.

## Features

- Custom event bus with access policy
- Event pattern rule for custom application events
- Scheduled rule with configurable expression (rate/cron)
- Lambda and SQS targets with retry policies
- Dead-letter queue for failed deliveries
- Event archive for replay capability
- CloudWatch alarms for failed invocations and DLQ depth

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply

# Send a test event
aws events put-events --entries '[{
  "EventBusName": "myapp-dev-events",
  "Source": "com.myapp.events",
  "DetailType": "OrderPlaced",
  "Detail": "{\"orderId\": \"123\", \"amount\": 99.99}"
}]'
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `event_source` | Event source name | `string` | `com.myapp.events` |
| `event_detail_types` | Detail types to match | `list(string)` | `[OrderPlaced, ...]` |
| `schedule_expression` | Schedule expression | `string` | `rate(1 hour)` |
| `archive_retention_days` | Archive retention | `number` | `30` |

## Outputs

| Name | Description |
|------|-------------|
| `event_bus_name` | Event bus name |
| `event_bus_arn` | Event bus ARN |
| `custom_events_rule_arn` | Custom events rule ARN |
| `scheduled_rule_arn` | Scheduled rule ARN |
