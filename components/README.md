# Components

Standalone infrastructure components that can be deployed independently. Each component wraps one or more modules from `modules/` and includes its own backend configuration and state management. Components are the primary unit of deployment in this repository.

## What Are Components?

| Concept | Purpose | State | Deployed by |
|---------|---------|-------|-------------|
| **Modules** | Reusable building blocks with clean interfaces | No own state -- used by callers | Not deployed directly |
| **Components** | Independently deployable infrastructure units | Own S3 backend state file | `terraform apply` per component |
| **Environments** | Full-stack compositions of modules for dev/staging/prod | Single state per environment | `terraform apply` per environment |

Components sit between modules and environments. They let you deploy and manage individual pieces of infrastructure without coupling everything into a single state file.

## Directory Structure

```
components/
├── acm/                    # TLS/SSL certificate management
├── alb/                    # Application Load Balancer
├── api-gateway/            # API Gateway REST/HTTP APIs
├── aurora/                 # Aurora PostgreSQL cluster
├── budgets/                # AWS Budget alerts and thresholds
├── cloudfront/             # CloudFront CDN distribution
├── cloudtrail/             # API audit logging
├── cloudwatch/             # CloudWatch dashboards and log groups
├── cognito/                # Cognito user pools and identity pools
├── dynamodb/               # DynamoDB tables
├── ebs/                    # EBS volumes
├── ec2/                    # EC2 instances
├── ecr/                    # Elastic Container Registry repositories
├── ecs-fargate/            # ECS Fargate services
├── efs/                    # Elastic File System
├── eks/                    # EKS Kubernetes cluster
├── elasticache/            # ElastiCache Redis cluster
├── eventbridge/            # EventBridge rules and buses
├── iam/                    # IAM roles and policies
├── internet-gateway/       # Internet Gateway
├── kms/                    # KMS encryption keys
├── lambda/                 # Lambda functions
├── nacl/                   # Network ACLs
├── nat-gateway/            # NAT Gateway
├── nlb/                    # Network Load Balancer
├── rds/                    # RDS PostgreSQL instance
├── route53/                # Route 53 DNS
├── s3/                     # S3 buckets
├── secrets-manager/        # Secrets Manager secrets
├── security-groups/        # Security groups
├── ses/                    # Simple Email Service
├── sns/                    # SNS topics (application messaging)
├── sns-alarms/             # SNS topics for alarm notifications
├── sqs/                    # SQS queues
├── ssm-parameter-store/    # SSM Parameter Store entries
├── step-functions/         # Step Functions state machines
├── transit-gateway/        # Transit Gateway for multi-VPC routing
├── vpc/                    # VPC and subnets
├── vpc-peering/            # VPC peering connections
├── waf/                    # Web Application Firewall
└── README.md
```

**Total: 41 components**

## Component Reference by Category

### Networking (10 components)

| Component | Description |
|-----------|-------------|
| `vpc` | VPC with public, private, and data subnets across multiple AZs |
| `internet-gateway` | Internet Gateway attached to VPC for public subnet routing |
| `nat-gateway` | NAT Gateway for outbound internet from private subnets |
| `security-groups` | Security groups for compute, database, and load balancer tiers |
| `nacl` | Network ACLs for subnet-level traffic filtering |
| `alb` | Application Load Balancer with HTTPS listeners and target groups |
| `nlb` | Network Load Balancer for TCP/UDP workloads |
| `cloudfront` | CloudFront CDN with S3 or ALB origins and cache behaviors |
| `route53` | Route 53 hosted zones, DNS records, and health checks |
| `transit-gateway` | Transit Gateway for routing between multiple VPCs |
| `vpc-peering` | VPC peering connections for cross-VPC communication |

### Security (7 components)

| Component | Description |
|-----------|-------------|
| `iam` | IAM roles, policies, and instance profiles |
| `kms` | KMS encryption keys with rotation and key policies |
| `acm` | TLS/SSL certificates with DNS validation via Route 53 |
| `secrets-manager` | Secrets storage with optional rotation configuration |
| `waf` | WAF web ACLs and rule groups attached to ALB or CloudFront |
| `cognito` | Cognito user pools, identity pools, and app clients |
| `ssm-parameter-store` | SSM Parameter Store for non-secret configuration values |

### Compute (3 components)

| Component | Description |
|-----------|-------------|
| `ec2` | EC2 instances with EBS volumes, user data, and IAM profiles |
| `lambda` | Lambda functions with IAM roles, layers, and event triggers |
| `step-functions` | Step Functions state machines for workflow orchestration |

### Containers (4 components)

| Component | Description |
|-----------|-------------|
| `ecr` | ECR repositories with lifecycle policies and image scanning |
| `ecs-fargate` | ECS Fargate cluster, services, and task definitions |
| `eks` | EKS cluster with managed node groups, add-ons, and IRSA |
| `api-gateway` | API Gateway REST or HTTP APIs with Lambda integrations |

### Database (4 components)

| Component | Description |
|-----------|-------------|
| `rds` | RDS PostgreSQL instance with parameter groups and backups |
| `aurora` | Aurora PostgreSQL cluster with reader instances |
| `dynamodb` | DynamoDB tables with GSIs, autoscaling, and streams |
| `elasticache` | ElastiCache Redis replication group with failover |

### Storage (3 components)

| Component | Description |
|-----------|-------------|
| `s3` | S3 buckets with versioning, lifecycle, encryption, and replication |
| `ebs` | EBS volumes with snapshots and encryption |
| `efs` | EFS file systems with mount targets and access points |

### Messaging (4 components)

| Component | Description |
|-----------|-------------|
| `sqs` | SQS queues with dead-letter queues and redrive policies |
| `sns` | SNS topics for application pub/sub messaging |
| `eventbridge` | EventBridge buses, rules, and targets |
| `ses` | SES email identities, configuration sets, and sending policies |

### Monitoring (4 components)

| Component | Description |
|-----------|-------------|
| `cloudwatch` | CloudWatch dashboards, log groups, and metric filters |
| `sns-alarms` | SNS topics dedicated to alarm notification routing |
| `cloudtrail` | CloudTrail API audit trails with S3 and CloudWatch delivery |
| `budgets` | AWS Budget alerts with cost and usage thresholds |

## Component File Structure

Each component directory contains:

```
components/{name}/
├── main.tf          # Module calls and resource composition
├── variables.tf     # Component-level inputs
├── outputs.tf       # Component-level outputs
├── versions.tf      # Terraform and provider version constraints
├── providers.tf     # Provider config and S3 backend configuration
├── data.tf          # Remote state data sources for cross-component references
└── README.md        # Usage instructions
```

## How to Deploy a Component

### Step 1: Configure Backend Variables

Ensure your S3 backend bucket and DynamoDB lock table exist (see `environments/_global/`).

### Step 2: Initialize Terraform

```bash
cd components/vpc
terraform init \
  -backend-config="bucket=myapp-terraform-state" \
  -backend-config="key=dev/vpc/terraform.tfstate" \
  -backend-config="region=ap-south-1" \
  -backend-config="dynamodb_table=myapp-terraform-locks"
```

### Step 3: Review the Plan

```bash
terraform plan -var-file="../../environments/dev/terraform.tfvars" -out=tfplan
```

### Step 4: Apply

```bash
terraform apply tfplan
```

### Step 5: Verify Outputs

```bash
terraform output
```

## Cross-Component References

Components reference each other through remote state data sources:

```hcl
# components/eks/data.tf
data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "myapp-terraform-state"
    key    = "${var.environment}/vpc/terraform.tfstate"
    region = "ap-south-1"
  }
}

locals {
  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids
}
```

## Deployment Dependency Order

Components must be deployed in dependency order. Components at the same level can be deployed in parallel.

```
Level 0 (no dependencies):
  vpc, iam, kms, s3, budgets, ssm-parameter-store

Level 1 (depends on VPC):
  internet-gateway, nat-gateway, security-groups, nacl

Level 2 (depends on Level 0-1):
  acm, secrets-manager, ecr, sqs, sns, eventbridge, ses,
  dynamodb, ebs, efs, cloudtrail, cloudwatch

Level 3 (depends on VPC + security-groups):
  rds, aurora, elasticache, ec2, lambda, step-functions,
  alb, nlb, transit-gateway, vpc-peering

Level 4 (depends on VPC + security-groups + IAM):
  eks, ecs-fargate, api-gateway, cognito

Level 5 (depends on ALB/EKS/S3):
  cloudfront, route53, waf, sns-alarms
```

**Simplified deployment sequence for a full stack:**

1. `vpc` -> `internet-gateway` -> `nat-gateway` -> `security-groups`
2. `iam` -> `kms` -> `secrets-manager`
3. `s3` -> `ecr`
4. `rds` or `aurora` -> `elasticache` -> `dynamodb`
5. `eks` or `ecs-fargate` -> `alb`
6. `acm` -> `cloudfront` -> `route53` -> `waf`
7. `cloudwatch` -> `sns-alarms` -> `cloudtrail` -> `budgets`

## Cost Considerations

Deploying all components will incur AWS costs. Here are the most significant:

| Component | Cost Driver | Estimated Monthly Cost (us-east-1) |
|-----------|-------------|-------------------------------------|
| `nat-gateway` | Per-hour charge + data processing | $32+ per NAT gateway |
| `eks` | Control plane hourly charge | $73 per cluster |
| `rds` / `aurora` | Instance hours + storage | $50-500+ depending on instance class |
| `elasticache` | Node hours | $25-200+ depending on node type |
| `alb` / `nlb` | LCU hours | $16-50+ |
| `cloudfront` | Data transfer + requests | Usage-dependent |
| `ec2` | Instance hours | Varies by instance type |
| `transit-gateway` | Per-attachment + data processing | $36+ per attachment |

**Tips to minimize costs during development:**

- Use `dev` environment sizing (smallest instance classes).
- Deploy only the components you need for your current work.
- Destroy components when not in use: `terraform destroy`.
- Use `budgets` component to set cost alerts.
- NAT gateways are one of the biggest hidden costs -- consider VPC endpoints for S3/DynamoDB as alternatives.

## Related Directories

- **[modules/](../modules/)** -- The reusable modules that components wrap.
- **[environments/](../environments/)** -- Full-stack environment configurations (`dev`, `staging`, `prod`) that compose modules directly.
- **[docs/04-aws-services-guide/](../docs/04-aws-services-guide/)** -- Service-level documentation for each AWS service.
