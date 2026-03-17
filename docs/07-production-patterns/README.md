# 07 - Production Patterns

Patterns and practices for running Terraform-managed infrastructure in production. This section covers the operational concerns that emerge at scale: multi-environment management, tagging, secrets, deployment strategies, disaster recovery, compliance, and cost optimization.

## Prerequisites

- Complete [01 - Terraform Basics](../01-terraform-basics/) through [04 - AWS Services Guide](../04-aws-services-guide/).
- Experience deploying infrastructure with Terraform in at least one environment.
- Familiarity with the `environments/` and `components/` directory structure in this repository.

## Learning Objectives

After completing this section, you will be able to:

- Design and implement a multi-environment strategy (dev/staging/prod) with Terraform
- Implement a consistent tagging strategy across all AWS resources
- Manage secrets securely with Secrets Manager, SSM Parameter Store, and SOPS
- Plan and execute blue-green and canary deployments for infrastructure changes
- Design and test disaster recovery plans (backup, restore, cross-region failover)
- Implement compliance guardrails with Sentinel, OPA, and AWS Config
- Optimize AWS costs through right-sizing, Reserved Instances, and resource scheduling

## Documents

| # | File | Description | Est. Reading Time |
|---|------|-------------|-------------------|
| 1 | [multi-environment.md](./multi-environment.md) | Strategies for managing dev/staging/prod: directory structure, variable files, workspace-based, and account-based separation. How the `environments/` directory implements this. | 20 min |
| 2 | [tagging-strategy.md](./tagging-strategy.md) | Mandatory and optional tags, tag enforcement with AWS Config and Terraform validation, cost allocation tags, and automation tags. | 10 min |
| 3 | [secrets-management.md](./secrets-management.md) | Secrets in Terraform: Secrets Manager, SSM Parameter Store, SOPS, Vault integration, and avoiding secrets in state files. | 15 min |
| 4 | [blue-green-canary.md](./blue-green-canary.md) | Blue-green and canary deployment patterns with Terraform: ALB weighted target groups, Route 53 weighted routing, and EKS rolling updates. | 15 min |
| 5 | [disaster-recovery.md](./disaster-recovery.md) | DR strategies (backup/restore, pilot light, warm standby, multi-region active-active), RTO/RPO targets, cross-region replication, and DR testing with Terraform. | 20 min |
| 6 | [compliance-and-governance.md](./compliance-and-governance.md) | Policy-as-code with Sentinel and OPA, AWS Config rules, SCPs for guardrails, drift detection, and audit trails with CloudTrail. | 15 min |
| 7 | [cost-optimization.md](./cost-optimization.md) | Right-sizing instances, Reserved Instances and Savings Plans, spot instances, resource scheduling (stop dev at night), S3 lifecycle policies, and budget alerts. | 15 min |

**Total estimated reading time: ~110 minutes**

## Suggested Reading Order

1. **Multi-environment** -- Read first; it shapes everything else.
2. **Tagging strategy** -- Implement early; retroactive tagging is painful.
3. **Secrets management** -- Read before your first production deployment.
4. **Cost optimization** -- Read before provisioning expensive resources.
5. **Blue-green/canary** -- Read when planning your deployment strategy.
6. **Disaster recovery** -- Read and plan before you need it.
7. **Compliance and governance** -- Read when your organization requires audit readiness.

## Hands-On Practice

- **Multi-environment:** Study the `environments/` directory -- `dev/`, `staging/`, `prod/`, and `_global/` show this pattern in action.
- **Tagging:** Every module in `modules/` implements the tagging convention described in `tagging-strategy.md`.
- **Secrets:** `components/secrets-manager/` and `components/kms/` demonstrate secret storage patterns. `components/ssm-parameter-store/` shows non-secret configuration.
- **Cost:** `components/budgets/` deploys AWS Budget alerts. `modules/cost/cur/` configures Cost and Usage Reports.
- **Compliance:** `components/cloudtrail/` enables API audit logging. `components/waf/` enforces web application security rules.

## What's Next

Continue to [08 - Workflows](../08-workflows/) for day-to-day developer workflows, team onboarding, and incident response procedures.
