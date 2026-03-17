# Onboarding Guide

## Overview

This guide walks new team members through setting up their development environment, getting access to infrastructure, understanding the codebase, and making their first infrastructure change via a pull request.

---

## Week 1 Checklist

### Day 1: Access and Setup

- [ ] **AWS access** — Request IAM Identity Center (SSO) access from your manager.
- [ ] **GitHub access** — Join the organization and infrastructure repositories.
- [ ] **Slack channels** — Join `#infrastructure`, `#alerts`, `#deploys`.
- [ ] **Documentation** — Read this guide and the [Developer Workflow](developer-workflow.md).

### Day 1-2: Local Environment Setup

```bash
# 1. Install prerequisites
# macOS:
brew install terraform tflint checkov awscli pre-commit jq kubectl helm

# Linux:
# See individual installation docs for each tool

# 2. Verify Terraform version
terraform version
# Expected: Terraform v1.9.x

# 3. Configure AWS CLI with SSO
aws configure sso
# Follow the prompts:
# SSO start URL: https://myorg.awsapps.com/start
# SSO Region: us-east-1
# Select your account and role

# 4. Test AWS access
aws sts get-caller-identity

# 5. Clone the infrastructure repository
git clone git@github.com:myorg/infrastructure.git
cd infrastructure

# 6. Set up pre-commit hooks
pre-commit install

# 7. Initialize Terraform for development
cd environments/development
terraform init

# 8. Run a plan to verify everything works
terraform plan
```

### Day 2-3: Understand the Architecture

Read these documents in order:

1. [Networking](../04-aws-services-guide/networking.md) — VPC and subnet design
2. [Compute](../04-aws-services-guide/compute.md) or [Containers](../04-aws-services-guide/containers.md) — How applications run
3. [Databases](../04-aws-services-guide/databases.md) — Data layer
4. [Multi-Environment](../07-production-patterns/multi-environment.md) — How environments are structured
5. [CI/CD Overview](../05-cicd/cicd-overview.md) — How changes are deployed

### Day 3-5: First PR

Complete the first PR exercise below.

---

## Repository Structure

```
infrastructure/
  modules/                    # Reusable Terraform modules
    vpc/                      # VPC, subnets, routing
    ecs/                      # ECS cluster, services, tasks
    rds/                      # RDS/Aurora databases
    redis/                    # ElastiCache Redis
    monitoring/               # CloudWatch dashboards, alarms

  environments/               # Per-environment configurations
    development/
      main.tf                 # Module calls
      variables.tf            # Variable definitions
      terraform.tfvars        # Environment-specific values
      backend.tf              # State backend config
      providers.tf            # Provider config
    staging/
      ...
    production/
      ...

  .github/
    workflows/
      terraform.yml           # CI/CD pipeline
      drift-detection.yml     # Scheduled drift checks

  docs/                       # Documentation (you are here)
```

---

## Key Concepts

### State

Terraform tracks the resources it manages in a **state file**. Our state is stored in S3 with DynamoDB locking. Never edit state files directly.

### Modules

Modules are reusable packages of Terraform configuration. Think of them like functions — they accept inputs (variables), create resources, and return outputs.

### Environments

Each environment (development, staging, production) has its own directory with its own state file, tfvars, and backend configuration. They all use the same modules.

### Plan and Apply

- `terraform plan` — shows what will change. Safe to run anytime.
- `terraform apply` — makes the changes. Only run through CI/CD in staging/production.

---

## Access Levels

| Role | Development | Staging | Production |
|------|-------------|---------|------------|
| New engineer (first 30 days) | Plan + Apply | Plan only | Plan only |
| Engineer | Plan + Apply | Plan + Apply | Plan only |
| Senior engineer | Plan + Apply | Plan + Apply | Plan + Apply (with approval) |
| Team lead | Full access | Full access | Full access |

You will start with read access to staging and production. After your first 30 days and successful PRs, your access will be expanded.

---

## First PR Walkthrough

### Exercise: Add a Tag to an Existing Resource

This is a safe, low-risk change that teaches the full workflow.

**Step 1: Create a branch**

```bash
cd infrastructure
git checkout main
git pull origin main
git checkout -b feat/add-team-tag-<your-name>
```

**Step 2: Make the change**

Open `environments/development/main.tf` and add a tag to any module call:

```hcl
module "vpc" {
  source = "../../modules/vpc"
  # ... existing config ...

  # Add this tag
  additional_tags = {
    OnboardedBy = "<your-name>"
  }
}
```

Or add a tag to a resource directly if the module does not support `additional_tags`.

**Step 3: Validate locally**

```bash
cd environments/development
terraform fmt -check
terraform validate
terraform plan
```

You should see a plan that updates tags on existing resources (no creates or destroys).

**Step 4: Commit and push**

```bash
git add .
git commit -m "feat(vpc): add OnboardedBy tag for onboarding exercise"
git push origin feat/add-team-tag-<your-name>
```

**Step 5: Open a PR**

- Go to GitHub and open a pull request.
- Fill in the PR description template.
- The CI pipeline will run `terraform plan` and post the output.
- Ask your onboarding buddy to review.

**Step 6: Review the plan**

- Read the plan output in the PR comment.
- Verify it only changes tags (no resource recreation).
- Confirm the changes are scoped to the development environment.

**Step 7: Merge and monitor**

- After approval, merge the PR.
- Watch the CI/CD pipeline apply the change.
- Verify in the AWS console that the tags were applied.

---

## AWS Console Access

You have read-only console access. Use it for:

- Viewing CloudWatch dashboards and logs
- Checking resource configurations
- Debugging issues

**Never make changes through the console.** All changes must go through Terraform and the PR process.

```bash
# Access the console via SSO
aws sso login --profile development
# Then open the console URL from the SSO portal
```

---

## kubectl Access (If Using EKS)

```bash
# Configure kubectl for the development cluster
aws eks update-kubeconfig --name development-eks --region us-east-1

# Verify access
kubectl get nodes
kubectl get pods -n app

# You have read-only access initially
kubectl get events -n app
kubectl logs -n app deployment/api --tail=50
```

---

## Learning Path

### Month 1: Foundations

- [ ] Complete the first PR exercise
- [ ] Read all guides in `docs/04-aws-services-guide/`
- [ ] Make 3 infrastructure PRs (tag changes, variable updates, etc.)
- [ ] Shadow a production deployment

### Month 2: Intermediate

- [ ] Read `docs/05-cicd/` and `docs/06-kubernetes/`
- [ ] Create a new module (e.g., CloudWatch dashboard)
- [ ] Review 5 infrastructure PRs from teammates
- [ ] Participate in an on-call rotation (shadow)

### Month 3: Advanced

- [ ] Read `docs/07-production-patterns/`
- [ ] Make a production change independently
- [ ] Write or update a runbook
- [ ] Lead a post-incident review

---

## Getting Help

| Question Type | Where to Ask |
|--------------|-------------|
| "How do I...?" | `#infrastructure` Slack channel |
| "This is broken" | `#alerts` + page on-call if SEV-1/2 |
| "Can I get access to...?" | Your manager |
| "Is this the right approach?" | PR comments or 1:1 with buddy |
| "What does this resource do?" | Read the module's `variables.tf` and `README.md` |

### Onboarding Buddy

You will be assigned an onboarding buddy who will:

- Review your first PRs
- Answer questions
- Walk you through the architecture
- Help with access issues

---

## Common Mistakes and How to Avoid Them

| Mistake | Prevention |
|---------|-----------|
| Running `terraform apply` locally on staging/production | CI/CD handles applies; you should only `plan` locally |
| Making changes in the AWS Console | All changes through Terraform PRs |
| Committing `.terraform/` directory | Already in `.gitignore`; verify before committing |
| Hardcoding values | Use variables with descriptions |
| Large PRs with many changes | Keep PRs small and focused |
| Forgetting to run `terraform init` after adding a module | Always init when module sources change |

---

## Related Guides

- [Developer Workflow](developer-workflow.md) — Day-to-day workflow details
- [CI/CD Overview](../05-cicd/cicd-overview.md) — How the pipeline works
- [Incident Response](incident-response.md) — When things go wrong
