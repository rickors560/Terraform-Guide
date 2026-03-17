# Modules

Reusable Terraform modules that encapsulate AWS resource groups behind clean input/output interfaces. Each module manages a single concern and can be composed together via components or environment configurations.

## Directory Structure

```
modules/
├── networking/
│   ├── vpc/                    # VPC, subnets, NAT gateways, route tables, VPC endpoints
│   ├── security-groups/        # Security group rules and ingress/egress definitions
│   ├── alb/                    # Application Load Balancer, listeners, target groups
│   ├── nlb/                    # Network Load Balancer, TCP/UDP listeners, target groups
│   ├── cloudfront/             # CloudFront distributions, origins, cache behaviors
│   └── route53/                # Hosted zones, DNS records, health checks
│
├── security/
│   ├── iam-role/               # IAM roles with assume-role policies
│   ├── iam-policy/             # IAM managed and inline policies
│   ├── kms/                    # KMS keys, aliases, key policies
│   ├── secrets-manager/        # Secrets Manager secrets and rotation config
│   ├── acm/                    # ACM certificates and DNS validation
│   └── waf/                    # WAF web ACLs, rules, and IP sets
│
├── compute/
│   ├── ec2-instance/           # EC2 instances with EBS, user data, IAM profiles
│   ├── asg/                    # Auto Scaling Groups with scaling policies
│   ├── launch-template/        # Launch templates for EC2 and ASG
│   └── lambda/                 # Lambda functions, layers, event source mappings
│
├── containers/
│   ├── ecr/                    # ECR repositories, lifecycle policies, scanning
│   ├── ecs-fargate/            # ECS cluster, Fargate services, task definitions
│   └── eks/
│       ├── cluster/            # EKS control plane, OIDC provider, security groups
│       ├── node-group/         # EKS managed node groups, launch templates
│       ├── addons/             # EKS add-ons (CoreDNS, kube-proxy, VPC CNI, EBS CSI)
│       └── irsa/               # IAM Roles for Service Accounts
│
├── database/
│   ├── rds-postgres/           # RDS PostgreSQL instances, parameter groups, read replicas
│   ├── aurora/                 # Aurora PostgreSQL clusters, instances, global databases
│   ├── dynamodb/               # DynamoDB tables, GSIs, autoscaling, streams
│   └── elasticache-redis/      # ElastiCache Redis clusters, replication groups, parameter groups
│
├── storage/
│   ├── s3/                     # S3 buckets, versioning, lifecycle, replication, encryption
│   ├── ebs/                    # EBS volumes, snapshots, encryption
│   └── efs/                    # EFS file systems, mount targets, access points
│
├── monitoring/
│   ├── cloudwatch-alarms/      # CloudWatch metric alarms, composite alarms
│   ├── cloudwatch-logs/        # CloudWatch log groups, retention, metric filters
│   ├── cloudwatch-dashboard/   # CloudWatch dashboards with JSON widget definitions
│   ├── sns-topic/              # SNS topics, subscriptions, delivery policies
│   └── cloudtrail/             # CloudTrail trails, S3 logging, CloudWatch integration
│
├── messaging/
│   ├── sqs/                    # SQS queues, dead-letter queues, redrive policies
│   ├── sns/                    # SNS topics for application messaging
│   └── eventbridge/            # EventBridge buses, rules, targets, archives
│
├── cicd/
│   ├── codepipeline/           # CodePipeline pipelines, stages, actions
│   ├── codebuild/              # CodeBuild projects, build specs, environments
│   └── github-oidc/            # GitHub OIDC identity provider and assume-role trust
│
└── cost/
    ├── budgets/                # AWS Budgets, alerts, thresholds
    └── cur/                    # Cost and Usage Reports, S3 delivery configuration
```

**Total: 42 modules across 10 categories**

## Complete Module Reference

### Networking (6 modules)

| Module | Path | Description | AWS Resources Created |
|--------|------|-------------|----------------------|
| VPC | `modules/networking/vpc` | Multi-AZ VPC with public, private, and data subnets | `aws_vpc`, `aws_subnet`, `aws_nat_gateway`, `aws_internet_gateway`, `aws_route_table`, `aws_vpc_endpoint` |
| Security Groups | `modules/networking/security-groups` | Security groups with configurable ingress/egress rules | `aws_security_group`, `aws_security_group_rule` |
| ALB | `modules/networking/alb` | Application Load Balancer with HTTPS listeners | `aws_lb`, `aws_lb_listener`, `aws_lb_target_group`, `aws_lb_listener_rule` |
| NLB | `modules/networking/nlb` | Network Load Balancer for TCP/UDP workloads | `aws_lb` (network), `aws_lb_listener`, `aws_lb_target_group` |
| CloudFront | `modules/networking/cloudfront` | CDN distribution with origin access control | `aws_cloudfront_distribution`, `aws_cloudfront_origin_access_control`, `aws_cloudfront_cache_policy` |
| Route 53 | `modules/networking/route53` | DNS hosted zones, records, and health checks | `aws_route53_zone`, `aws_route53_record`, `aws_route53_health_check` |

### Security (6 modules)

| Module | Path | Description | AWS Resources Created |
|--------|------|-------------|----------------------|
| IAM Role | `modules/security/iam-role` | IAM roles with trust policies and managed policy attachments | `aws_iam_role`, `aws_iam_role_policy_attachment`, `aws_iam_instance_profile` |
| IAM Policy | `modules/security/iam-policy` | Custom IAM policies with JSON policy documents | `aws_iam_policy` |
| KMS | `modules/security/kms` | Encryption keys with rotation and key policies | `aws_kms_key`, `aws_kms_alias`, `aws_kms_grant` |
| Secrets Manager | `modules/security/secrets-manager` | Secrets with optional automatic rotation | `aws_secretsmanager_secret`, `aws_secretsmanager_secret_version`, `aws_secretsmanager_secret_rotation` |
| ACM | `modules/security/acm` | TLS/SSL certificates with DNS validation | `aws_acm_certificate`, `aws_acm_certificate_validation` |
| WAF | `modules/security/waf` | Web Application Firewall rules and IP sets | `aws_wafv2_web_acl`, `aws_wafv2_rule_group`, `aws_wafv2_ip_set` |

### Compute (4 modules)

| Module | Path | Description | AWS Resources Created |
|--------|------|-------------|----------------------|
| EC2 Instance | `modules/compute/ec2-instance` | EC2 instances with EBS, user data, and IAM profiles | `aws_instance`, `aws_ebs_volume`, `aws_volume_attachment` |
| ASG | `modules/compute/asg` | Auto Scaling Groups with scaling policies | `aws_autoscaling_group`, `aws_autoscaling_policy`, `aws_autoscaling_schedule` |
| Launch Template | `modules/compute/launch-template` | Launch templates for EC2 and ASG use | `aws_launch_template` |
| Lambda | `modules/compute/lambda` | Lambda functions with IAM, layers, and triggers | `aws_lambda_function`, `aws_lambda_layer_version`, `aws_lambda_event_source_mapping`, `aws_lambda_permission` |

### Containers (6 modules)

| Module | Path | Description | AWS Resources Created |
|--------|------|-------------|----------------------|
| ECR | `modules/containers/ecr` | Container image repositories with lifecycle and scanning | `aws_ecr_repository`, `aws_ecr_lifecycle_policy`, `aws_ecr_repository_policy` |
| ECS Fargate | `modules/containers/ecs-fargate` | ECS cluster with Fargate services and task definitions | `aws_ecs_cluster`, `aws_ecs_service`, `aws_ecs_task_definition` |
| EKS Cluster | `modules/containers/eks/cluster` | EKS control plane with OIDC provider | `aws_eks_cluster`, `aws_iam_openid_connect_provider`, `aws_cloudwatch_log_group` |
| EKS Node Group | `modules/containers/eks/node-group` | Managed node groups with configurable instance types | `aws_eks_node_group`, `aws_launch_template` |
| EKS Addons | `modules/containers/eks/addons` | Cluster add-ons (CoreDNS, kube-proxy, VPC CNI, EBS CSI) | `aws_eks_addon` |
| EKS IRSA | `modules/containers/eks/irsa` | IAM Roles for Kubernetes Service Accounts | `aws_iam_role`, `aws_iam_policy`, `aws_iam_role_policy_attachment` |

### Database (4 modules)

| Module | Path | Description | AWS Resources Created |
|--------|------|-------------|----------------------|
| RDS PostgreSQL | `modules/database/rds-postgres` | RDS PostgreSQL with parameter groups and read replicas | `aws_db_instance`, `aws_db_subnet_group`, `aws_db_parameter_group` |
| Aurora | `modules/database/aurora` | Aurora PostgreSQL clusters with reader instances | `aws_rds_cluster`, `aws_rds_cluster_instance`, `aws_rds_cluster_parameter_group` |
| DynamoDB | `modules/database/dynamodb` | DynamoDB tables with GSIs and autoscaling | `aws_dynamodb_table`, `aws_appautoscaling_target`, `aws_appautoscaling_policy` |
| ElastiCache Redis | `modules/database/elasticache-redis` | Redis replication groups with parameter groups | `aws_elasticache_replication_group`, `aws_elasticache_subnet_group`, `aws_elasticache_parameter_group` |

### Storage (3 modules)

| Module | Path | Description | AWS Resources Created |
|--------|------|-------------|----------------------|
| S3 | `modules/storage/s3` | S3 buckets with versioning, lifecycle, encryption, replication | `aws_s3_bucket`, `aws_s3_bucket_versioning`, `aws_s3_bucket_lifecycle_configuration`, `aws_s3_bucket_server_side_encryption_configuration` |
| EBS | `modules/storage/ebs` | EBS volumes with snapshots and encryption | `aws_ebs_volume`, `aws_ebs_snapshot`, `aws_ebs_encryption_by_default` |
| EFS | `modules/storage/efs` | EFS file systems with mount targets and access points | `aws_efs_file_system`, `aws_efs_mount_target`, `aws_efs_access_point` |

### Monitoring (5 modules)

| Module | Path | Description | AWS Resources Created |
|--------|------|-------------|----------------------|
| CloudWatch Alarms | `modules/monitoring/cloudwatch-alarms` | Metric and composite alarms with SNS actions | `aws_cloudwatch_metric_alarm`, `aws_cloudwatch_composite_alarm` |
| CloudWatch Logs | `modules/monitoring/cloudwatch-logs` | Log groups with retention and metric filters | `aws_cloudwatch_log_group`, `aws_cloudwatch_log_metric_filter` |
| CloudWatch Dashboard | `modules/monitoring/cloudwatch-dashboard` | Dashboards with JSON widget definitions | `aws_cloudwatch_dashboard` |
| SNS Topic | `modules/monitoring/sns-topic` | SNS topics for alarm notifications | `aws_sns_topic`, `aws_sns_topic_subscription`, `aws_sns_topic_policy` |
| CloudTrail | `modules/monitoring/cloudtrail` | API audit trails with S3 and CloudWatch integration | `aws_cloudtrail`, `aws_cloudwatch_log_group` |

### Messaging (3 modules)

| Module | Path | Description | AWS Resources Created |
|--------|------|-------------|----------------------|
| SQS | `modules/messaging/sqs` | SQS queues with dead-letter queues and redrive policies | `aws_sqs_queue`, `aws_sqs_queue_policy`, `aws_sqs_queue_redrive_policy` |
| SNS | `modules/messaging/sns` | SNS topics for application-level pub/sub messaging | `aws_sns_topic`, `aws_sns_topic_subscription` |
| EventBridge | `modules/messaging/eventbridge` | Event buses, rules, and targets for event-driven architectures | `aws_cloudwatch_event_bus`, `aws_cloudwatch_event_rule`, `aws_cloudwatch_event_target` |

### CI/CD (3 modules)

| Module | Path | Description | AWS Resources Created |
|--------|------|-------------|----------------------|
| CodePipeline | `modules/cicd/codepipeline` | CI/CD pipelines with source, build, and deploy stages | `aws_codepipeline`, `aws_iam_role`, `aws_s3_bucket` (artifact store) |
| CodeBuild | `modules/cicd/codebuild` | Build projects with configurable environments | `aws_codebuild_project`, `aws_iam_role`, `aws_cloudwatch_log_group` |
| GitHub OIDC | `modules/cicd/github-oidc` | GitHub Actions OIDC federation for AWS authentication | `aws_iam_openid_connect_provider`, `aws_iam_role` |

### Cost (2 modules)

| Module | Path | Description | AWS Resources Created |
|--------|------|-------------|----------------------|
| Budgets | `modules/cost/budgets` | AWS Budget alerts with thresholds and notifications | `aws_budgets_budget` |
| CUR | `modules/cost/cur` | Cost and Usage Report delivery to S3 | `aws_cur_report_definition`, `aws_s3_bucket` |

## Module Conventions

### File Structure

Every module follows this standard layout:

```
modules/{category}/{name}/
├── main.tf              # Primary resource definitions
├── variables.tf         # Input variable declarations
├── outputs.tf           # Output value declarations
├── versions.tf          # Terraform and provider version constraints
├── locals.tf            # Computed values and name construction
├── README.md            # Auto-generated by terraform-docs
└── examples/
    └── complete/        # Full working example
        └── main.tf
```

### Naming Convention

All resources use a consistent naming prefix:

```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
}
```

Resource names follow the pattern `{project}-{environment}-{component}`, for example: `myapp-prod-web-alb`.

### Tagging Strategy

Every resource includes the standard tag set:

```hcl
tags = merge(var.tags, {
  Name        = "${local.name_prefix}-{component}"
  Component   = "{module-name}"
  Environment = var.environment
  ManagedBy   = "terraform"
})
```

### Inputs and Outputs

- Every variable has a `description` and `type`.
- Validation blocks enforce constraints (e.g., CIDR ranges, environment names, string lengths).
- Every output has a `description`.
- Sensitive outputs (passwords, keys) are marked with `sensitive = true`.
- Outputs that other modules depend on are clearly documented.

## How to Use Modules

### From an Environment Configuration

Environment root configurations in `environments/` compose multiple modules together:

```hcl
# environments/prod/main.tf
module "vpc" {
  source = "../../modules/networking/vpc"

  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = "10.0.0.0/16"
  azs          = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  tags         = var.tags
}

module "eks_cluster" {
  source = "../../modules/containers/eks/cluster"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  tags               = var.tags
}
```

### From a Standalone Component

Components in `components/` wrap one or more modules with their own backend and provider configuration:

```hcl
# components/eks/main.tf
module "eks_cluster" {
  source = "../../modules/containers/eks/cluster"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = local.vpc_id              # from remote state
  private_subnet_ids = local.private_subnet_ids  # from remote state
  tags               = var.tags
}

module "eks_node_group" {
  source = "../../modules/containers/eks/node-group"

  cluster_name    = module.eks_cluster.cluster_name
  node_group_name = "default"
  instance_types  = ["t3.medium"]
  desired_size    = 3
  tags            = var.tags
}
```

### Source Path Reference

When referencing modules, always use relative paths from the calling configuration:

| Calling from | Source path pattern |
|---|---|
| `environments/{env}/main.tf` | `../../modules/{category}/{name}` |
| `components/{name}/main.tf` | `../../modules/{category}/{name}` |
| `modules/{cat}/{name}/examples/complete/main.tf` | `../../` (two levels up to the module root) |

## Module Dependencies

Modules are designed to be composable. Here is how they relate to each other:

```
                    ┌─────────────────────┐
                    │   networking/vpc     │  (Foundation - deploy first)
                    └──────────┬──────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
              v                v                v
     security/            networking/       networking/
     security-groups      alb, nlb         route53
              │                │                │
              v                v                v
     ┌────────┴───────┐  ┌────┴─────┐   ┌─────┴──────┐
     │ compute/       │  │containers│   │  security/  │
     │ ec2, asg,      │  │ eks,     │   │  acm, waf   │
     │ lambda         │  │ ecs,ecr  │   │             │
     └────────┬───────┘  └────┬─────┘   └─────┬──────┘
              │               │               │
              v               v               v
     ┌────────┴───────────────┴───────────────┴──────┐
     │  database/ (rds, aurora, dynamodb, elasticache)│
     │  storage/ (s3, ebs, efs)                       │
     └────────────────────┬──────────────────────────┘
                          │
                          v
     ┌────────────────────┴──────────────────────────┐
     │  monitoring/ (alarms, logs, dashboards, trail) │
     │  messaging/ (sqs, sns, eventbridge)            │
     │  cost/ (budgets, cur)                          │
     └───────────────────────────────────────────────┘
```

**Key dependency chains:**

1. **VPC first** -- Nearly every other module needs `vpc_id` and `subnet_ids`.
2. **Security groups** -- Compute, containers, and database modules reference security group IDs.
3. **IAM roles/policies** -- Compute, containers, and CI/CD modules need IAM role ARNs.
4. **KMS keys** -- Database, storage, and secrets modules reference KMS key ARNs for encryption.
5. **Monitoring last** -- Alarms and dashboards reference resources created by all other modules.

## Related Directories

- **[environments/](../environments/)** -- `dev`, `staging`, `prod`, and `_global` configurations that compose these modules into full environments.
- **[components/](../components/)** -- Standalone deployable units that wrap these modules with their own state management.
- **[docs/04-aws-services-guide/](../docs/04-aws-services-guide/)** -- Detailed documentation on each AWS service these modules manage.
