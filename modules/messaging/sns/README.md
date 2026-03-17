# SNS Pub/Sub Module

Terraform module for AWS SNS Topics focused on pub/sub messaging patterns with message filtering, cross-account access, and FIFO support.

## Features

- Standard and FIFO topic support with deduplication
- Message filtering policies per subscription
- Cross-account publish and subscribe access
- AWS service principal access policies
- Dead-letter queue redrive for failed deliveries
- Raw message delivery for SQS/HTTP subscribers
- KMS encryption
- X-Ray tracing support
- Message archiving (archive policy)
- Consistent naming and tagging

## Usage

```hcl
module "sns_events" {
  source = "../../modules/messaging/sns"

  project     = "myapp"
  environment = "prod"
  name        = "order-events"

  subscriptions = [
    {
      name     = "fulfillment-queue"
      protocol = "sqs"
      endpoint = "arn:aws:sqs:us-east-1:123456789012:fulfillment"
      raw_message_delivery = true
      filter_policy = jsonencode({
        eventType = ["OrderCreated", "OrderUpdated"]
      })
    },
    {
      name     = "analytics-queue"
      protocol = "sqs"
      endpoint = "arn:aws:sqs:us-east-1:123456789012:analytics"
      raw_message_delivery = true
      filter_policy = jsonencode({
        eventType = ["OrderCreated"]
      })
    }
  ]

  cross_account_ids = ["111111111111"]
  allowed_services  = ["events.amazonaws.com"]
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
| name | Topic name suffix | string | - | yes |
| fifo_topic | Create FIFO topic | bool | false | no |
| subscriptions | List of subscriptions with filtering | list(object) | [] | no |
| cross_account_ids | Accounts with publish/subscribe access | list(string) | [] | no |
| allowed_services | Service principals with publish access | list(string) | [] | no |

## Outputs

| Name | Description |
|------|-------------|
| topic_arn | ARN of the SNS topic |
| topic_name | Name of the SNS topic |
| subscription_arns | Map of subscription names to ARNs |
