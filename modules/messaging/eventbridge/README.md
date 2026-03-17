# EventBridge Module

Terraform module to create and manage AWS EventBridge event buses, rules, targets, and archives.

## Features

- Custom event bus creation or use existing/default bus
- Event rules with patterns and schedule expressions
- Multiple target types: Lambda, SQS, SNS, Step Functions, ECS
- Input transformation for targets
- Dead-letter queue for failed target invocations
- Retry policy configuration per target
- Event archives with configurable retention
- Event bus resource-based policy for cross-account access
- ECS Fargate task targets with network configuration
- Consistent naming and tagging

## Usage

```hcl
module "eventbridge" {
  source = "../../modules/messaging/eventbridge"

  project     = "myapp"
  environment = "prod"
  bus_name    = "application"

  rules = [
    {
      name = "order-created"
      event_pattern = jsonencode({
        source      = ["myapp.orders"]
        detail-type = ["OrderCreated"]
      })
      targets = [
        {
          target_id = "process-order"
          arn       = "arn:aws:lambda:us-east-1:123456789012:function:process-order"
        }
      ]
    },
    {
      name                = "daily-cleanup"
      schedule_expression = "rate(1 day)"
      targets = [
        {
          target_id = "cleanup-lambda"
          arn       = "arn:aws:lambda:us-east-1:123456789012:function:cleanup"
        }
      ]
    }
  ]

  archives = [
    {
      name           = "all-events"
      retention_days = 90
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
| bus_name | Event bus name | string | - | yes |
| create_bus | Create custom bus | bool | true | no |
| rules | List of rules with targets | list(object) | [] | no |
| archives | List of event archives | list(object) | [] | no |
| bus_policy | Resource-based policy JSON | string | null | no |

## Outputs

| Name | Description |
|------|-------------|
| bus_name | Event bus name |
| bus_arn | Event bus ARN |
| rule_arns | Map of rule names to ARNs |
| archive_arns | Map of archive names to ARNs |
