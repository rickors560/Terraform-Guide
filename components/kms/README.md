# KMS Component

This component creates AWS KMS keys for different purposes (general, S3, RDS, EBS), each with proper key policies, aliases, automatic rotation, and optional multi-region support. It also supports KMS grants for fine-grained access control.

## Architecture

- **General-Purpose Key**: For SNS, SQS, CloudWatch Logs, and other services
- **S3 Key**: Dedicated to S3 bucket encryption with S3 service principal access
- **RDS Key**: Dedicated to RDS database encryption with grant permissions
- **EBS Key**: Dedicated to EBS volume encryption scoped to EC2 service via ViaService condition
- All keys have automatic rotation enabled and configurable deletion windows

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name                        | Description                              | Type         | Default     |
|-----------------------------|------------------------------------------|--------------|-------------|
| region                      | AWS region                               | string       | ap-south-1  |
| project_name                | Project name for naming                  | string       | n/a         |
| environment                 | Environment name                         | string       | n/a         |
| deletion_window_in_days     | Days before permanent deletion           | number       | 30          |
| rotation_period_in_days     | Days between automatic rotations         | number       | 365         |
| enable_multi_region         | Create multi-region primary keys         | bool         | false       |
| key_admin_arns              | IAM ARNs for key administration          | list(string) | []          |
| key_user_arns               | IAM ARNs for key usage                   | list(string) | []          |
| allowed_service_principals  | AWS services for general key             | list(string) | [logs, sns, sqs] |
| kms_grants                  | Grants on the general-purpose key        | map(object)  | {}          |

## Outputs

| Name              | Description                    |
|-------------------|--------------------------------|
| general_key_arn   | ARN of the general-purpose key |
| s3_key_arn        | ARN of the S3 key              |
| rds_key_arn       | ARN of the RDS key             |
| ebs_key_arn       | ARN of the EBS key             |
