# Production Environment

Full production infrastructure with high availability, security, and comprehensive monitoring.

## Architecture

- **VPC**: 10.2.0.0/16, 3 AZs, NAT Gateway per AZ
- **EKS**: On-Demand (t3.large, 3-10) + Spot mixed (t3.large/xlarge, 0-10)
- **RDS PostgreSQL**: db.r6g.large, multi-AZ, KMS encryption, performance insights (2yr retention), enhanced monitoring (15s), SSL enforced
- **ElastiCache Redis**: cache.r6g.large, cluster mode (2 shards, 1 replica each), encryption at rest and in transit
- **ALB**: HTTPS with TLS 1.3, WAF protection, session stickiness
- **WAF**: Rate limiting, AWS managed rules (common, bad inputs, SQLi)
- **S3**: KMS-encrypted, versioned, lifecycle policies
- **ECR**: KMS-encrypted, immutable tags, lifecycle policies
- **CloudTrail**: Multi-region, S3 + CloudWatch Logs, log file validation
- **CloudWatch**: Full dashboard, alarms with severity tiers (warning/critical SNS topics)
- **KMS**: Dedicated keys for general, RDS, and S3 encryption
- **Secrets Manager**: RDS credentials, application secrets
- **ACM**: Wildcard certificate with DNS validation
- **Budgets**: Monthly cost budget with 80%/100% threshold alerts

## Security Features

- Strict security groups (no open egress from RDS/Redis)
- Private EKS endpoint only (no public API access)
- WAF with rate limiting and managed rule sets
- KMS encryption for all data stores
- CloudTrail for API audit logging
- RDS SSL enforcement
- IMDSv2 required on all instances

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Prerequisites

- Global environment applied first (Route53 zone, IAM roles)
- S3 backend bucket and DynamoDB lock table exist
- Domain registrar NS records pointing to Route53

## Deployment Order

1. Apply `environments/_global/` first
2. Note the Route53 zone ID from global outputs
3. Set `route53_zone_id` in prod terraform.tfvars
4. Apply `environments/prod/`
