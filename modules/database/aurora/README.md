# Aurora PostgreSQL Module

Terraform module to create an AWS Aurora PostgreSQL cluster with configurable instances, Serverless v2 scaling, global database support, encryption, backups, and IAM authentication.

## Features

- Aurora PostgreSQL cluster with configurable instances
- Serverless v2 scaling option
- Global database support
- Subnet group and parameter groups (cluster + instance)
- KMS encryption and backup configuration
- IAM database authentication
- Performance Insights
- CloudWatch log exports
- Secrets Manager for master password

## Usage

```hcl
module "aurora" {
  source = "../../modules/database/aurora"

  project     = "myapp"
  environment = "prod"

  engine_version = "16.3"
  instance_count = 2
  instance_class = "db.r6g.large"

  subnet_ids             = var.private_subnet_ids
  vpc_security_group_ids = [aws_security_group.aurora.id]

  deletion_protection = true

  team = "platform"
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
| cluster_endpoint | Writer endpoint |
| cluster_reader_endpoint | Reader endpoint |
| cluster_arn | Cluster ARN |
