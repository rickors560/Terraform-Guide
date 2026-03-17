# CloudWatch Logs Module

Terraform module to create and manage AWS CloudWatch Log Groups with metric filters and subscription filters.

## Features

- Configurable log group with retention period and encryption
- Log group class selection (STANDARD or INFREQUENT_ACCESS)
- Metric filters with transformation support
- Subscription filters for Lambda, Kinesis, or Firehose destinations
- KMS encryption support
- Consistent naming and tagging

## Usage

```hcl
module "cloudwatch_logs" {
  source = "../../modules/monitoring/cloudwatch-logs"

  project     = "myapp"
  environment = "prod"
  component   = "api"

  retention_in_days = 90
  kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/xxx"

  metric_filters = [
    {
      name             = "error-count"
      pattern          = "[timestamp, level = \"ERROR\", ...]"
      metric_namespace = "MyApp/API"
      metric_name      = "ErrorCount"
      metric_value     = "1"
    }
  ]

  subscription_filters = [
    {
      name            = "to-elasticsearch"
      filter_pattern  = ""
      destination_arn = "arn:aws:lambda:us-east-1:123456789012:function:log-shipper"
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
| component | Component name for log group path | string | "application" | no |
| retention_in_days | Log retention period | number | 30 | no |
| kms_key_id | KMS key ARN for encryption | string | null | no |
| metric_filters | List of metric filter configs | list(object) | [] | no |
| subscription_filters | List of subscription filter configs | list(object) | [] | no |

## Outputs

| Name | Description |
|------|-------------|
| log_group_name | Name of the log group |
| log_group_arn | ARN of the log group |
| metric_filter_ids | Map of metric filter names to IDs |
| subscription_filter_ids | Map of subscription filter names to IDs |
