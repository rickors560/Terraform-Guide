# CloudTrail Module

Terraform module to create and manage AWS CloudTrail with S3 bucket, CloudWatch Logs integration, encryption, and event selectors.

## Features

- CloudTrail trail with multi-region support
- Auto-created S3 bucket with bucket policy, versioning, and encryption
- CloudWatch Logs integration with IAM role
- KMS encryption for logs
- Management and data event selectors
- Insight selectors (API call rate, API error rate)
- Log file integrity validation
- S3 lifecycle rules for cost optimization
- Consistent naming and tagging

## Usage

```hcl
module "cloudtrail" {
  source = "../../modules/monitoring/cloudtrail"

  project     = "myapp"
  environment = "prod"

  is_multi_region_trail  = true
  enable_cloudwatch_logs = true

  data_events = [
    {
      read_write_type = "All"
      data_resources = [
        {
          type   = "AWS::S3::Object"
          values = ["arn:aws:s3"]
        }
      ]
    }
  ]

  insight_selectors = [
    { insight_type = "ApiCallRateInsight" }
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
| is_multi_region_trail | Multi-region trail | bool | true | no |
| enable_cloudwatch_logs | Enable CW Logs | bool | true | no |
| kms_key_arn | KMS key ARN | string | null | no |
| data_events | Data event selectors | list(object) | [] | no |
| insight_selectors | Insight types | list(object) | [] | no |

## Outputs

| Name | Description |
|------|-------------|
| trail_arn | ARN of the trail |
| s3_bucket_id | S3 bucket ID |
| cloudwatch_log_group_arn | CloudWatch Log Group ARN |
