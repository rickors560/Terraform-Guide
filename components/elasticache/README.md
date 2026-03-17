# ElastiCache Component

Production-grade ElastiCache Redis replication group with encryption, AUTH token, automatic failover, and CloudWatch logging.

## Features

- Redis 7.1 replication group with automatic failover
- Transit and at-rest encryption
- AUTH token stored in Secrets Manager
- Custom parameter group with slow log configuration
- Multi-AZ deployment with 2+ nodes
- Automatic snapshots with configurable retention
- Slow log and engine log delivery to CloudWatch
- CloudWatch alarms for CPU and memory utilization

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
| `node_type` | Node type | `string` | `cache.t3.micro` |
| `num_cache_clusters` | Number of nodes | `number` | `2` |
| `engine_version` | Redis version | `string` | `7.1` |

## Outputs

| Name | Description |
|------|-------------|
| `primary_endpoint` | Primary (write) endpoint |
| `reader_endpoint` | Reader endpoint |
| `auth_secret_arn` | Secrets Manager ARN for auth token |
| `security_group_id` | Security group ID |
