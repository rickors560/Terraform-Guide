# CloudTrail Component

This component creates a CloudTrail trail with S3 bucket storage (versioning, lifecycle, encryption), CloudWatch Logs integration, KMS encryption, event selectors for S3 and Lambda data events, insight selectors, and security metric filters with alarms for unauthorized API calls, console login without MFA, and root account usage.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                          | Description                      | Type         | Default |
|-------------------------------|----------------------------------|--------------|---------|
| project_name                  | Project name for naming          | string       | n/a     |
| environment                   | Environment name                 | string       | n/a     |
| is_multi_region               | Multi-region trail               | bool         | true    |
| enable_insights               | Enable CloudTrail Insights       | bool         | true    |
| log_retention_days            | S3 log retention days            | number       | 730     |
| cloudwatch_log_retention_days | CloudWatch log retention days    | number       | 90      |
| alarm_sns_topic_arns          | SNS topics for alarms            | list(string) | []      |

## Outputs

| Name                    | Description                     |
|-------------------------|---------------------------------|
| trail_arn               | ARN of the CloudTrail trail     |
| s3_bucket_arn           | ARN of the log storage bucket   |
| cloudwatch_log_group_arn| ARN of the CW log group         |
| kms_key_arn             | ARN of the encryption key       |
