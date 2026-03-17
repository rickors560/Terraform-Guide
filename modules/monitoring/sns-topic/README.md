# SNS Topic Module

Terraform module to create and manage AWS SNS Topics with subscriptions, encryption, and access policies.

## Features

- Standard and FIFO topic support
- KMS encryption
- Multiple subscription types (email, SMS, Lambda, SQS, HTTPS)
- Custom access and delivery policies
- Filter policies for subscriptions
- Dead-letter queue (redrive policy) for subscriptions
- Consistent naming and tagging

## Usage

```hcl
module "sns_topic" {
  source = "../../modules/monitoring/sns-topic"

  project     = "myapp"
  environment = "prod"
  name        = "alerts"

  display_name      = "Application Alerts"
  kms_master_key_id = "alias/aws/sns"

  subscriptions = [
    {
      protocol = "email"
      endpoint = "ops@example.com"
    },
    {
      protocol = "lambda"
      endpoint = "arn:aws:lambda:us-east-1:123456789012:function:handler"
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
| name | Topic name suffix | string | - | yes |
| display_name | Display name | string | "" | no |
| fifo_topic | Create FIFO topic | bool | false | no |
| kms_master_key_id | KMS key for encryption | string | null | no |
| subscriptions | List of subscriptions | list(object) | [] | no |
| policy | Topic access policy JSON | string | null | no |
| delivery_policy | Delivery policy JSON | string | null | no |

## Outputs

| Name | Description |
|------|-------------|
| topic_arn | ARN of the SNS topic |
| topic_id | ID of the SNS topic |
| topic_name | Name of the SNS topic |
| subscription_arns | Map of subscription ARNs |
