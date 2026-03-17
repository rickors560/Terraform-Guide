# RDS PostgreSQL Module

Terraform module to create an AWS RDS PostgreSQL instance with Multi-AZ, encryption, automated backups, Performance Insights, and enhanced monitoring.

## Features

- RDS PostgreSQL with configurable engine version
- Multi-AZ deployment option
- DB subnet group and parameter group
- KMS encryption for storage
- Automated backups with configurable retention and window
- Maintenance window configuration
- Performance Insights with optional KMS encryption
- Enhanced monitoring with IAM role
- Final snapshot toggle and deletion protection
- Secrets Manager integration for master password
- IAM database authentication
- CloudWatch log exports

## Usage

```hcl
module "rds_postgres" {
  source = "../../modules/database/rds-postgres"

  project     = "myapp"
  environment = "prod"

  engine_version = "16.3"
  instance_class = "db.r6g.large"

  allocated_storage     = 100
  max_allocated_storage = 500

  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = true
  deletion_protection = true

  team        = "platform"
  cost_center = "CC-1234"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_endpoint | RDS endpoint |
| db_instance_arn | RDS ARN |
| db_name | Database name |
| master_user_secret_arn | Secrets Manager secret ARN |
