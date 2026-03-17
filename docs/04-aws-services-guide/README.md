# 04 - AWS Services Guide

A comprehensive reference for every AWS service managed by this repository. Each document covers a service category: what the service does, key concepts, how it is modeled in Terraform, configuration patterns, and cost considerations.

## Prerequisites

- Basic AWS knowledge (console navigation, IAM basics, regions/AZs).
- Completion of [01 - Terraform Basics](../01-terraform-basics/) is recommended so you can read the Terraform examples.
- An AWS account for hands-on experimentation.

## Learning Objectives

After completing this section, you will be able to:

- Understand the purpose and key features of each AWS service in this repository
- Map AWS service concepts to their Terraform resource representations
- Choose the right service for a given use case (e.g., RDS vs. Aurora, SQS vs. EventBridge)
- Configure services following AWS Well-Architected best practices
- Estimate costs for each service category
- Connect the documentation to the corresponding modules and components

## Documents

| # | File | Description | Est. Reading Time |
|---|------|-------------|-------------------|
| 1 | [networking.md](./networking.md) | VPC fundamentals: subnets, route tables, internet gateways, NAT gateways, VPC endpoints, and security groups. | 20 min |
| 2 | [networking-advanced.md](./networking-advanced.md) | Advanced networking: transit gateways, VPC peering, PrivateLink, Direct Connect, NACLs, and flow logs. | 15 min |
| 3 | [compute.md](./compute.md) | EC2 instances, AMIs, instance types, placement groups, Auto Scaling Groups, launch templates, and Elastic IPs. | 15 min |
| 4 | [containers.md](./containers.md) | ECR, ECS (Fargate and EC2 launch type), EKS, task definitions, services, and container networking. | 20 min |
| 5 | [databases.md](./databases.md) | RDS PostgreSQL, Aurora, DynamoDB, and ElastiCache Redis. Instance sizing, backups, replication, and failover. | 20 min |
| 6 | [storage.md](./storage.md) | S3 (buckets, lifecycle, replication, encryption), EBS (volumes, snapshots, types), and EFS (file systems, access points). | 15 min |
| 7 | [security.md](./security.md) | IAM (roles, policies, OIDC), KMS encryption, ACM certificates, Secrets Manager, WAF, and Security Hub. | 20 min |
| 8 | [monitoring.md](./monitoring.md) | CloudWatch (metrics, alarms, logs, dashboards), CloudTrail, SNS notifications, and X-Ray tracing. | 15 min |
| 9 | [messaging.md](./messaging.md) | SQS queues, SNS topics, EventBridge buses and rules, and choosing between messaging services. | 10 min |
| 10 | [serverless.md](./serverless.md) | Lambda functions, API Gateway, Step Functions, Cognito, and SES. Event-driven architectures with Terraform. | 15 min |
| 11 | [cost-management.md](./cost-management.md) | AWS Budgets, Cost and Usage Reports (CUR), cost allocation tags, Reserved Instances, Savings Plans, and cost optimization strategies. | 10 min |

**Total estimated reading time: ~175 minutes**

## Suggested Reading Order

You do not need to read all 11 documents sequentially. Choose based on your needs:

**For a full-stack web application:**
1. `networking.md` -> `security.md` -> `compute.md` or `containers.md` -> `databases.md` -> `storage.md` -> `monitoring.md`

**For a serverless application:**
1. `networking.md` -> `security.md` -> `serverless.md` -> `messaging.md` -> `storage.md` -> `monitoring.md`

**For cost planning:**
1. Start with `cost-management.md`, then read the cost sections within each relevant service guide.

## Mapping to Modules and Components

| Document | Related Modules | Related Components |
|----------|----------------|-------------------|
| networking.md | `modules/networking/vpc`, `security-groups`, `alb`, `nlb` | `vpc`, `security-groups`, `alb`, `nlb`, `internet-gateway`, `nat-gateway` |
| networking-advanced.md | `modules/networking/cloudfront`, `route53` | `cloudfront`, `route53`, `transit-gateway`, `vpc-peering`, `nacl` |
| compute.md | `modules/compute/ec2-instance`, `asg`, `launch-template` | `ec2` |
| containers.md | `modules/containers/ecr`, `ecs-fargate`, `eks/*` | `ecr`, `ecs-fargate`, `eks` |
| databases.md | `modules/database/rds-postgres`, `aurora`, `dynamodb`, `elasticache-redis` | `rds`, `aurora`, `dynamodb`, `elasticache` |
| storage.md | `modules/storage/s3`, `ebs`, `efs` | `s3`, `ebs`, `efs` |
| security.md | `modules/security/iam-role`, `iam-policy`, `kms`, `secrets-manager`, `acm`, `waf` | `iam`, `kms`, `secrets-manager`, `acm`, `waf`, `cognito` |
| monitoring.md | `modules/monitoring/cloudwatch-alarms`, `cloudwatch-logs`, `cloudwatch-dashboard`, `sns-topic`, `cloudtrail` | `cloudwatch`, `sns-alarms`, `cloudtrail` |
| messaging.md | `modules/messaging/sqs`, `sns`, `eventbridge` | `sqs`, `sns`, `eventbridge`, `ses` |
| serverless.md | `modules/compute/lambda` | `lambda`, `api-gateway`, `step-functions`, `cognito` |
| cost-management.md | `modules/cost/budgets`, `cur` | `budgets` |

## What's Next

- Continue to [05 - CI/CD](../05-cicd/) to learn how to automate Terraform deployments.
- Jump to [06 - Kubernetes](../06-kubernetes/) if you are deploying EKS clusters.
- See [07 - Production Patterns](../07-production-patterns/) for architecture patterns that span multiple services.
