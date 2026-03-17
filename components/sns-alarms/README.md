# SNS Alarms Component

This component creates an SNS-based alarm notification system with three severity-tiered topics (critical, warning, info), KMS encryption, email subscriptions, a Lambda function for alarm enrichment, and example CloudWatch alarms for EC2 CPU, RDS connections, and ALB 5xx errors that forward to the appropriate topic.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                      | Description                  | Type         | Default |
|---------------------------|------------------------------|--------------|---------|
| project_name              | Project name for naming      | string       | n/a     |
| environment               | Environment name             | string       | n/a     |
| critical_email_endpoints  | Emails for critical alerts   | list(string) | []      |
| warning_email_endpoints   | Emails for warning alerts    | list(string) | []      |
| rds_connections_threshold | RDS connections alarm limit  | number       | 100     |
| alb_5xx_threshold         | ALB 5xx alarm limit          | number       | 10      |

## Outputs

| Name                        | Description                        |
|-----------------------------|------------------------------------|
| critical_topic_arn          | ARN of the critical topic          |
| warning_topic_arn           | ARN of the warning topic           |
| info_topic_arn              | ARN of the info topic              |
| alarm_processor_function_arn| ARN of the Lambda processor        |
