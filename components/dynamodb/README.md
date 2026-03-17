# DynamoDB Component

Production-grade DynamoDB table with single-table design pattern (GSI, LSI), TTL, PITR, encryption, and auto-scaling.

## Features

- Single-table design with PK/SK hash/range keys
- Global Secondary Index (GSI1) for alternate access patterns
- Local Secondary Index (LSI1) for additional sort key
- TTL for automatic item expiration
- Point-in-Time Recovery (PITR)
- Server-side encryption (AWS-owned or customer KMS key)
- On-demand (PAY_PER_REQUEST) or provisioned billing mode
- Auto-scaling for table and GSI capacity (provisioned mode)
- Optional DynamoDB Streams
- Deletion protection in production

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
| `table_name` | Table name suffix | `string` | `main` |
| `billing_mode` | PROVISIONED or PAY_PER_REQUEST | `string` | `PAY_PER_REQUEST` |
| `hash_key` | Partition key name | `string` | `PK` |
| `range_key` | Sort key name | `string` | `SK` |
| `ttl_enabled` | Enable TTL | `bool` | `true` |
| `pitr_enabled` | Enable PITR | `bool` | `true` |
| `enable_autoscaling` | Enable auto-scaling | `bool` | `false` |

## Outputs

| Name | Description |
|------|-------------|
| `table_name` | DynamoDB table name |
| `table_arn` | Table ARN |
| `stream_arn` | Stream ARN (if enabled) |
