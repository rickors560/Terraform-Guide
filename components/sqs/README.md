# SQS Component

Production-grade SQS queue with dead-letter queue, encryption, access policies, and CloudWatch alarms.

## Features

- Standard or FIFO queue with configurable settings
- Dead-letter queue with redrive policy
- SSE encryption (SQS-managed or KMS)
- Access policies enforcing TLS and same-account access
- SNS publish permission included
- Long polling enabled (20-second wait)
- CloudWatch alarms for queue depth, DLQ messages, and message age

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `queue_name` | Queue name suffix | `string` | `main` |
| `fifo_queue` | Create FIFO queue | `bool` | `false` |
| `visibility_timeout_seconds` | Visibility timeout | `number` | `60` |
| `max_receive_count` | Max receives before DLQ | `number` | `3` |

## Outputs

| Name | Description |
|------|-------------|
| `queue_url` | Queue URL |
| `queue_arn` | Queue ARN |
| `dlq_url` | Dead-letter queue URL |
| `dlq_arn` | Dead-letter queue ARN |
