# SNS Component

Production-grade SNS topic with email, SQS, and Lambda subscriptions, encryption, access policies, and delivery configuration.

## Features

- Standard or FIFO topic
- KMS encryption (AWS-managed SNS key by default)
- Topic policy allowing CloudWatch, EventBridge, and same-account access
- TLS enforcement
- Email, SQS, and Lambda subscriptions
- Raw message delivery for SQS
- Optional message filtering
- CloudWatch alarm for failed notifications

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

Note: Email subscriptions require manual confirmation via the link sent to the email address.

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `topic_name` | Topic name suffix | `string` | `notifications` |
| `email_subscribers` | Email addresses | `list(string)` | `[]` |
| `sqs_subscriber_arns` | SQS queue ARNs | `list(string)` | `[]` |
| `lambda_subscriber_arns` | Lambda ARNs | `list(string)` | `[]` |

## Outputs

| Name | Description |
|------|-------------|
| `topic_arn` | SNS topic ARN |
| `topic_name` | SNS topic name |
