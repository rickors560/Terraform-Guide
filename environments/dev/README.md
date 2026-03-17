# Dev Environment

Cost-optimized development environment for rapid iteration and testing.

## Architecture

- **VPC**: 10.0.0.0/16, 2 AZs, single NAT Gateway
- **EKS**: t3.medium nodes, 1-3 scaling
- **RDS PostgreSQL**: db.t3.micro, single-AZ, no multi-AZ
- **ElastiCache Redis**: cache.t3.micro, single node
- **ALB**: Public-facing with HTTP-to-HTTPS redirect
- **S3**: App assets bucket, ALB logs bucket
- **ECR**: Repositories for API, Web, and Worker images
- **CloudWatch**: Basic alarms for RDS CPU, storage, and ALB 5XX errors

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Cost Optimization

- Single NAT Gateway (not per-AZ)
- Smallest instance sizes (t3.micro/t3.medium)
- Single-AZ RDS (no multi-AZ replication)
- Single Redis node
- Short log retention (14 days)
- Force-destroy enabled on S3 buckets for easy teardown

## Prerequisites

- Global environment applied first (for Route53, IAM roles)
- S3 backend bucket and DynamoDB lock table exist
