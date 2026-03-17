# SQS Queue Module

Terraform module to create and manage AWS SQS queues with dead-letter queue support, encryption, and access policies.

## Features

- Standard and FIFO queue support
- Automatic dead-letter queue creation
- KMS and SQS-managed encryption
- Configurable message retention, visibility timeout, and delay
- Redrive policy and redrive allow policy
- Content-based deduplication for FIFO queues
- High-throughput FIFO mode support
- Access policy configuration
- Consistent naming and tagging

## Usage

```hcl
module "sqs" {
  source = "../../modules/messaging/sqs"

  project     = "myapp"
  environment = "prod"
  name        = "orders"

  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600
  delay_seconds              = 0
  receive_wait_time_seconds  = 10

  create_dlq            = true
  dlq_max_receive_count = 3

  sqs_managed_sse_enabled = true
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
| name | Queue name suffix | string | - | yes |
| fifo_queue | Create FIFO queue | bool | false | no |
| visibility_timeout_seconds | Visibility timeout | number | 30 | no |
| message_retention_seconds | Message retention | number | 345600 | no |
| create_dlq | Create dead-letter queue | bool | true | no |
| dlq_max_receive_count | Max receives before DLQ | number | 3 | no |

## Outputs

| Name | Description |
|------|-------------|
| queue_arn | ARN of the queue |
| queue_url | URL of the queue |
| dlq_arn | ARN of the dead-letter queue |
| dlq_url | URL of the dead-letter queue |
