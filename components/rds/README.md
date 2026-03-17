# RDS Component

Production-grade RDS PostgreSQL instance with encryption, automated backups, CloudWatch alarms, and Secrets Manager integration.

## Features

- PostgreSQL 16 with custom parameter group (SSL enforced, query logging, pg_stat_statements)
- Storage encryption with AWS-managed or customer-managed KMS key
- Automated backups with configurable retention
- Multi-AZ deployment support
- Storage autoscaling
- Performance Insights enabled
- CloudWatch alarms for CPU, storage, memory, and connections
- Credentials stored in Secrets Manager
- CloudWatch Logs export for PostgreSQL and upgrade logs

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_db_instance` | PostgreSQL RDS instance |
| `aws_db_subnet_group` | Subnet group for multi-AZ |
| `aws_db_parameter_group` | Custom PostgreSQL parameters |
| `aws_security_group` | RDS security group |
| `aws_secretsmanager_secret` | Credentials secret |
| `aws_cloudwatch_metric_alarm` | CPU, storage, memory, connections alarms |
| `random_password` | Master password generation |

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Retrieving Credentials

```bash
aws secretsmanager get-secret-value \
  --secret-id myapp/dev/rds/credentials \
  --query SecretString --output text | jq .
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vpc_id` | VPC ID | `string` | — |
| `subnet_ids` | Subnet IDs (min 2) | `list(string)` | — |
| `instance_class` | Instance class | `string` | `db.t3.micro` |
| `allocated_storage` | Storage (GB) | `number` | `20` |
| `multi_az` | Multi-AZ | `bool` | `false` |
| `backup_retention_period` | Backup days | `number` | `7` |

## Outputs

| Name | Description |
|------|-------------|
| `db_endpoint` | Connection endpoint |
| `db_address` | Hostname |
| `credentials_secret_arn` | Secrets Manager ARN |
| `db_security_group_id` | Security group ID |
