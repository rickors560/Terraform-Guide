# Staging Environment

Production mirror with smaller sizing for pre-release validation.

## Architecture

- **VPC**: 10.1.0.0/16, 2 AZs, single NAT Gateway
- **EKS**: t3.medium nodes, 2-4 scaling
- **RDS PostgreSQL**: db.t3.small, multi-AZ, enhanced monitoring, performance insights
- **ElastiCache Redis**: cache.t3.small, 2-node replication group with automatic failover
- **ALB**: Public-facing with deletion protection
- **S3**: App assets (versioned, KMS encrypted), ALB logs (lifecycle rules)
- **ECR**: Immutable tags for release integrity
- **CloudWatch**: Alarms with SNS notification for RDS, ALB, and Redis

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Differences from Production

- Smaller instance sizes (t3.medium vs t3.large/xlarge)
- 2 AZs instead of 3
- Single NAT Gateway instead of per-AZ
- Fewer EKS nodes
- Smaller RDS instance class

## Prerequisites

- Global environment applied first
- S3 backend bucket and DynamoDB lock table exist
