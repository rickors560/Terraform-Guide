# Learning Path

A structured, phase-by-phase curriculum that takes you from Terraform beginner to production-grade AWS infrastructure expert. Each phase builds on the previous one.

---

## Phase 0 — Project Setup and Conventions

**Complexity:** Beginner
**Estimated Time:** 1–2 hours
**Prerequisites:** None

Set up the repository structure, tooling, linting, and conventions that every subsequent phase depends on.

**What you will learn:**
- Repository layout for multi-environment Terraform projects
- Naming conventions (`{project}-{environment}-{component}-{qualifier}`)
- Tagging strategy for cost allocation and governance
- Remote state backend with S3 and DynamoDB
- Pre-commit hooks for code quality (terraform fmt, tflint, checkov)
- Makefile-driven workflows

**Key files:**
- `bootstrap/` — Remote backend infrastructure
- `Makefile` — Automation targets
- `.pre-commit-config.yaml` — Git hooks
- `.editorconfig` — Editor settings

---

## Phase 1 — Networking (VPC, Subnets, NAT)

**Complexity:** Beginner
**Estimated Time:** 3–4 hours
**Prerequisites:** Phase 0 completed, basic understanding of IP addressing and CIDR notation

Design and provision a production-grade VPC with public, private, and data subnets across multiple availability zones.

**What you will learn:**
- VPC architecture with three-tier subnet design
- NAT Gateways for outbound internet access from private subnets
- Route tables, internet gateways, and VPC endpoints
- Terraform `cidrsubnet()` function for address planning
- Module composition and input/output contracts

**Key files:**
- `modules/networking/` — Reusable VPC module
- `components/vpc/` — Standalone VPC component
- `environments/dev/` — Dev environment wiring

---

## Phase 2 — Security (Security Groups, NACLs, IAM)

**Complexity:** Beginner to Intermediate
**Estimated Time:** 3–4 hours
**Prerequisites:** Phase 1 completed, understanding of TCP/UDP ports, basic IAM concepts

Build layered network and identity security controls.

**What you will learn:**
- Security group design with least-privilege ingress/egress rules
- Network ACLs as a secondary defense layer
- IAM roles, policies, and instance profiles
- IRSA (IAM Roles for Service Accounts) preparation for EKS
- Terraform `for_each` and dynamic blocks for rule generation

**Key files:**
- `modules/security/` — Security group and IAM modules
- `modules/iam/` — Reusable IAM role module

---

## Phase 3 — Compute (EKS Cluster and Node Groups)

**Complexity:** Intermediate
**Estimated Time:** 5–6 hours
**Prerequisites:** Phases 1–2 completed, basic Kubernetes concepts (pods, services, deployments)

Provision a managed EKS cluster with self-managed and managed node groups.

**What you will learn:**
- EKS cluster creation with private endpoint access
- Managed node groups with launch templates
- EKS add-ons (CoreDNS, kube-proxy, vpc-cni, ebs-csi-driver)
- OIDC provider for IRSA
- `kubectl` configuration and cluster authentication
- Terraform `aws_eks_cluster` and `aws_eks_node_group` resources

**Key files:**
- `modules/compute/` — EKS module
- `components/eks/` — Standalone EKS component

---

## Phase 4 — Database (RDS and ElastiCache)

**Complexity:** Intermediate
**Estimated Time:** 4–5 hours
**Prerequisites:** Phases 1–2 completed, basic SQL and caching concepts

Deploy managed database and caching layers in private subnets.

**What you will learn:**
- RDS PostgreSQL with Multi-AZ and read replicas
- Subnet groups, parameter groups, and option groups
- ElastiCache Redis in cluster mode
- Encryption at rest and in transit with KMS
- Automated backups and maintenance windows
- Secrets Manager integration for credentials

**Key files:**
- `modules/database/` — RDS and ElastiCache modules
- `components/rds/` — Standalone RDS component
- `components/elasticache/` — Standalone ElastiCache component

---

## Phase 5 — Storage and CDN (S3, CloudFront, Route 53)

**Complexity:** Intermediate
**Estimated Time:** 4–5 hours
**Prerequisites:** Phases 1–2 completed, understanding of DNS and HTTP caching

Set up object storage, a CDN for global content delivery, and DNS management.

**What you will learn:**
- S3 buckets with versioning, lifecycle rules, and replication
- Bucket policies and access points
- CloudFront distributions with origin access control
- Route 53 hosted zones, records, and health checks
- ACM certificate provisioning and DNS validation
- Terraform `aws_s3_bucket_*` resource decomposition pattern

**Key files:**
- `modules/storage/` — S3 module
- `modules/cdn/` — CloudFront module
- `modules/dns/` — Route 53 module
- `components/s3/` — Standalone S3 component
- `components/cloudfront/` — Standalone CloudFront component
- `components/route53/` — Standalone Route 53 component

---

## Phase 6 — Load Balancing (ALB and Target Groups)

**Complexity:** Intermediate
**Estimated Time:** 3–4 hours
**Prerequisites:** Phases 1–3 completed, understanding of HTTP/HTTPS and TLS

Provision an Application Load Balancer with path-based routing and TLS termination.

**What you will learn:**
- ALB with multiple listeners (HTTP redirect, HTTPS)
- Target groups with health checks
- Path-based and host-based routing rules
- ALB access logging to S3
- AWS Load Balancer Controller for EKS integration
- Terraform `aws_lb_listener_rule` for complex routing

**Key files:**
- `components/alb/` — Standalone ALB component

---

## Phase 7 — Application Deployment (Kubernetes Manifests)

**Complexity:** Intermediate to Advanced
**Estimated Time:** 5–6 hours
**Prerequisites:** Phases 1–6 completed, familiarity with Docker, Kubernetes Deployments and Services

Deploy a multi-tier application (frontend, backend, workers) to EKS using Kubernetes manifests and Kustomize overlays.

**What you will learn:**
- Deployment, Service, Ingress, HPA, PDB manifests
- Kustomize base and overlay pattern for multi-environment
- ConfigMaps and Secrets from Secrets Manager (External Secrets Operator)
- Resource requests and limits, pod disruption budgets
- Helm values files for third-party chart configuration

**Key files:**
- `k8s/base/` — Kustomize base manifests
- `k8s/overlays/` — Per-environment overlays
- `application/` — Sample frontend and backend code

---

## Phase 8 — Observability (CloudWatch, Prometheus, Grafana)

**Complexity:** Advanced
**Estimated Time:** 5–6 hours
**Prerequisites:** Phases 1–7 completed, understanding of metrics, logs, and traces

Build a full observability stack: metrics collection, dashboards, alerting, and log aggregation.

**What you will learn:**
- CloudWatch metrics, alarms, and composite alarms
- CloudWatch Log Groups with retention policies
- Prometheus installation via Helm on EKS
- Grafana dashboards for cluster and application metrics
- SNS topics for alarm notifications
- Terraform `aws_cloudwatch_metric_alarm` with math expressions

**Key files:**
- `modules/monitoring/` — CloudWatch module

---

## Phase 9 — CI/CD (GitHub Actions, ArgoCD)

**Complexity:** Advanced
**Estimated Time:** 5–6 hours
**Prerequisites:** All previous phases completed, familiarity with Git workflows and CI/CD concepts

Automate infrastructure and application delivery with GitHub Actions for Terraform and ArgoCD for Kubernetes.

**What you will learn:**
- GitHub Actions workflows for `terraform plan` on PRs
- Automated `terraform apply` on merge to main
- OIDC federation for keyless AWS authentication from GitHub Actions
- ArgoCD installation and Application CRDs
- GitOps workflow: code push triggers automatic deployment
- Branch protection rules and required status checks

**Key files:**
- `.github/workflows/` — CI/CD pipeline definitions
- `docs/architecture/` — CI/CD architecture diagrams

---

## Phase 10 — Production Hardening (WAF, Backups, DR)

**Complexity:** Advanced
**Estimated Time:** 6–8 hours
**Prerequisites:** All previous phases completed

Apply production-grade security, backup, disaster recovery, and compliance controls.

**What you will learn:**
- AWS WAF v2 with managed rule groups and custom rules
- AWS Backup plans and vaults for RDS and EFS
- Cross-region replication for S3 and RDS
- VPC Flow Logs and CloudTrail for audit
- AWS Config rules for compliance checks
- Terraform `moved` blocks for safe refactoring
- State import and `terraform import` for brownfield adoption

**Key files:**
- `docs/runbooks/` — Operational runbooks

---

## Suggested Schedule

| Week | Phases | Focus |
|---|---|---|
| 1 | 0, 1 | Setup, networking fundamentals |
| 2 | 2, 3 | Security, EKS cluster |
| 3 | 4, 5 | Databases, storage, CDN |
| 4 | 6, 7 | Load balancing, application deployment |
| 5 | 8, 9 | Observability, CI/CD automation |
| 6 | 10 | Production hardening and review |

## Tips for Success

1. **Deploy to a personal AWS account** — Use the AWS Free Tier where possible, but expect some costs (NAT Gateway, EKS control plane, RDS).
2. **Always destroy after learning** — Run `make destroy ENV=dev` when you are done with a phase to avoid ongoing charges.
3. **Read the Terraform docs** — Each phase references specific Terraform resources. Read the official documentation for those resources alongside this guide.
4. **Use `terraform plan` liberally** — Never apply without reviewing the plan. Make it a habit.
5. **Commit often** — Each phase is a natural commit boundary. Use meaningful commit messages.
