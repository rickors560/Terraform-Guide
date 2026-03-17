# 05 - CI/CD

Automating Terraform workflows with CI/CD pipelines. This section covers how to safely run Terraform in automated environments, from GitHub Actions to Atlantis to Terraform Cloud, with emphasis on security and drift detection.

## Prerequisites

- Complete [01 - Terraform Basics](../01-terraform-basics/) and [02 - Terraform Intermediate](../02-terraform-intermediate/).
- Basic familiarity with GitHub Actions (YAML workflow syntax, triggers, jobs).
- Understanding of Git branching workflows (pull requests, code review).

## Learning Objectives

After completing this section, you will be able to:

- Design a CI/CD pipeline for Terraform with plan-on-PR and apply-on-merge
- Set up GitHub Actions workflows for Terraform with proper credential management
- Configure Atlantis for pull-request-driven Terraform automation
- Use Terraform Cloud with VCS integration for remote plan and apply
- Secure CI/CD pipelines (OIDC authentication, least-privilege roles, plan approval gates)
- Detect and alert on infrastructure drift between state and reality

## Documents

| # | File | Description | Est. Reading Time |
|---|------|-------------|-------------------|
| 1 | [cicd-overview.md](./cicd-overview.md) | Why automate Terraform, CI/CD pipeline patterns (plan-on-PR, apply-on-merge), approval workflows, and choosing a CI/CD tool. | 10 min |
| 2 | [github-actions-terraform.md](./github-actions-terraform.md) | Complete GitHub Actions workflow for Terraform: checkout, setup-terraform, init, plan, apply, PR comments with plan output, and OIDC authentication. | 20 min |
| 3 | [atlantis.md](./atlantis.md) | Atlantis setup, `atlantis.yaml` configuration, project auto-detection, plan/apply commands in PR comments, and locking. | 15 min |
| 4 | [terraform-cloud-vcs.md](./terraform-cloud-vcs.md) | Terraform Cloud VCS-driven workflows, speculative plans, cost estimation, Sentinel policies, and workspace configuration. | 15 min |
| 5 | [pipeline-security.md](./pipeline-security.md) | Securing the pipeline: OIDC for AWS authentication (no long-lived keys), least-privilege IAM roles, plan approval gates, secret handling, and audit logging. | 15 min |
| 6 | [drift-detection.md](./drift-detection.md) | Detecting configuration drift: scheduled plan jobs, `terraform plan -detailed-exitcode`, alerting on drift, and remediation strategies. | 10 min |

**Total estimated reading time: ~85 minutes**

## Suggested Reading Order

1. Start with `cicd-overview.md` for the big picture.
2. Read the tool you plan to use: `github-actions-terraform.md`, `atlantis.md`, or `terraform-cloud-vcs.md`.
3. Read `pipeline-security.md` regardless of your tool choice.
4. Add `drift-detection.md` once your pipeline is running.

## Hands-On Practice

- **GitHub OIDC module:** `modules/cicd/github-oidc/` sets up the OIDC provider and IAM role for GitHub Actions.
- **CodePipeline module:** `modules/cicd/codepipeline/` and `modules/cicd/codebuild/` for AWS-native CI/CD.
- **Pipeline security:** Study the IAM policies in `modules/security/iam-role/` and `modules/security/iam-policy/` for crafting least-privilege pipeline roles.

## What's Next

Continue to [06 - Kubernetes](../06-kubernetes/) to learn about deploying and managing EKS clusters, or skip to [07 - Production Patterns](../07-production-patterns/) for multi-environment and disaster recovery patterns.
