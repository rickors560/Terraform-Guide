# Aurora Component

Production-grade Aurora PostgreSQL cluster with multiple instances, encryption, enhanced monitoring, and auto-scaling.

## Features

- Aurora PostgreSQL 16 cluster with writer and reader instances
- Cluster and instance parameter groups with SSL enforcement
- Storage encryption (AWS-managed or customer KMS key)
- Enhanced monitoring with dedicated IAM role
- Performance Insights enabled
- Read replica auto-scaling based on CPU utilization
- Credentials stored in Secrets Manager
- CloudWatch Logs export

## Resources Created

| Resource | Description |
|----------|-------------|
| `aws_rds_cluster` | Aurora PostgreSQL cluster |
| `aws_rds_cluster_instance` | Cluster instances (writer + readers) |
| `aws_db_subnet_group` | Subnet group |
| `aws_rds_cluster_parameter_group` | Cluster parameters |
| `aws_db_parameter_group` | Instance parameters |
| `aws_security_group` | Cluster security group |
| `aws_secretsmanager_secret` | Credentials secret |
| `aws_appautoscaling_target/policy` | Read replica auto-scaling |
| `aws_iam_role` | Enhanced monitoring role |

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
| `vpc_id` | VPC ID | `string` | — |
| `subnet_ids` | Subnet IDs | `list(string)` | — |
| `instance_class` | Instance class | `string` | `db.r6g.large` |
| `instance_count` | Number of instances | `number` | `2` |
| `enable_autoscaling` | Enable read replica scaling | `bool` | `false` |

## Outputs

| Name | Description |
|------|-------------|
| `cluster_endpoint` | Writer endpoint |
| `reader_endpoint` | Reader endpoint |
| `credentials_secret_arn` | Secrets Manager ARN |
