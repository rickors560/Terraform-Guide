# Terraform Cloud

## Table of Contents

- [Overview](#overview)
- [Getting Started](#getting-started)
- [Workspaces in Terraform Cloud](#workspaces-in-terraform-cloud)
- [VCS Integration](#vcs-integration)
- [Remote Execution](#remote-execution)
- [Variables and Variable Sets](#variables-and-variable-sets)
- [Sentinel Policies](#sentinel-policies)
- [Cost Estimation](#cost-estimation)
- [Private Registry](#private-registry)
- [Team Management and RBAC](#team-management-and-rbac)
- [Run Triggers and Notifications](#run-triggers-and-notifications)
- [API-Driven Workflows](#api-driven-workflows)
- [Best Practices](#best-practices)

---

## Overview

Terraform Cloud (also known as HCP Terraform) is HashiCorp's managed platform for Terraform collaboration. It provides remote state management, remote execution, policy enforcement, and team collaboration features that address the challenges of running Terraform in a team environment.

### Key Features

| Feature | Description |
|---------|-------------|
| Remote State | Encrypted state storage with locking and versioning |
| Remote Execution | Run plans and applies on Terraform Cloud servers |
| VCS Integration | Trigger runs from Git commits and pull requests |
| Sentinel Policies | Policy-as-code enforcement before infrastructure changes |
| Cost Estimation | Estimate monthly costs before applying changes |
| Private Registry | Host and share private modules and providers |
| Team Management | RBAC for controlling who can plan, apply, and admin |
| Run Triggers | Chain workspaces so one apply triggers another |
| Notifications | Slack, email, and webhook notifications for run status |

### Terraform Cloud vs Terraform Enterprise

| Aspect | Terraform Cloud | Terraform Enterprise |
|--------|----------------|---------------------|
| Hosting | SaaS (HashiCorp-hosted) | Self-hosted |
| Pricing | Free tier + paid plans | Enterprise license |
| Network | Public internet | Your private network |
| Compliance | SOC 2 Type II | Your compliance scope |
| SSO/SAML | Business tier and above | Included |
| Audit Logging | Business tier and above | Included |
| Agents | Business tier and above | Included |

---

## Getting Started

### Create an Account

1. Go to [app.terraform.io](https://app.terraform.io)
2. Create an account and organization
3. Authenticate the CLI

### CLI Authentication

```bash
terraform login
# Opens a browser for authentication
# Stores the token in ~/.terraform.d/credentials.tfrc.json
```

For CI/CD systems, use a token directly:

```bash
export TF_TOKEN_app_terraform_io="your-team-or-user-token"
```

Or create a credentials file:

```hcl
# ~/.terraform.d/credentials.tfrc.json
{
  "credentials": {
    "app.terraform.io": {
      "token": "your-api-token"
    }
  }
}
```

### Configure Your Project

```hcl
terraform {
  cloud {
    organization = "my-organization"

    workspaces {
      name = "my-app-production"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

### Initialize

```bash
terraform init
# Initializing Terraform Cloud...
# Terraform Cloud has been successfully initialized!
```

---

## Workspaces in Terraform Cloud

Each Terraform Cloud workspace is an independent unit of infrastructure management with its own state, variables, permissions, and run history.

### Workspace Creation Methods

**CLI:**

```bash
terraform workspace new production
```

**Using the cloud block with tags:**

```hcl
terraform {
  cloud {
    organization = "my-org"
    workspaces {
      tags = ["app:web", "env:prod"]
    }
  }
}
```

**API:**

```bash
curl -s \
  --header "Authorization: Bearer $TF_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data '{
    "data": {
      "type": "workspaces",
      "attributes": {
        "name": "my-app-prod",
        "terraform_version": "1.7.3",
        "auto-apply": false
      }
    }
  }' \
  "https://app.terraform.io/api/v2/organizations/my-org/workspaces"
```

### Workspace Settings

| Setting | Description |
|---------|-------------|
| Execution Mode | Remote (runs on TFC), Local (runs locally), or Agent |
| Terraform Version | Pin the Terraform version for this workspace |
| Auto Apply | Automatically apply successful plans (useful for dev) |
| Working Directory | Subdirectory containing the Terraform config |
| VCS Branch | Git branch to watch for changes |
| Run Triggers | Other workspaces that trigger runs in this workspace |

### Workspace Naming Convention

```
<application>-<component>-<environment>

Examples:
  web-app-networking-prod
  web-app-compute-prod
  web-app-database-prod
  web-app-networking-dev
```

---

## VCS Integration

Terraform Cloud can connect to GitHub, GitLab, Bitbucket, and Azure DevOps. Changes pushed to a branch automatically trigger Terraform runs.

### Workflow

```
Developer pushes code
        |
        v
Terraform Cloud detects change
        |
        v
Automatic plan runs
        |
        v
Plan output posted as PR comment
        |
        v
Reviewer approves PR
        |
        v
Merge triggers apply (if auto-apply) or manual confirm
```

### Configuring VCS

1. In Terraform Cloud, go to Settings > VCS Providers
2. Connect your GitHub/GitLab organization
3. Create a workspace linked to a repository
4. Set the working directory if the Terraform config is in a subdirectory

### Speculative Plans

When a pull request is opened, Terraform Cloud runs a **speculative plan** (plan-only, no apply). The plan output is posted as a PR comment, giving reviewers visibility into infrastructure changes before merge.

```
GitHub PR #42: Add production database
  ├── terraform plan (speculative)
  │   Plan: 3 to add, 0 to change, 0 to destroy
  └── Posted as PR status check
```

### Trigger Patterns

Control which file changes trigger a run:

- **Auto-trigger on all changes**: Default behavior
- **Working directory filter**: Only trigger on changes within the configured working directory
- **Trigger prefixes**: Only trigger on changes to specific paths
- **File triggers**: Specify exact file patterns

---

## Remote Execution

When execution mode is set to "Remote," Terraform Cloud runs plans and applies on its own infrastructure.

### Benefits

- No need for cloud credentials on developer machines
- Consistent execution environment
- Run history and audit trail
- Team members see real-time output

### How It Works

```bash
# Running locally, but execution happens remotely
terraform plan
# Running plan in Terraform Cloud. Output will stream here.
# Waiting for the plan to start...
#
# Terraform v1.7.3
# Planning...
# Plan: 2 to add, 0 to change, 0 to destroy.
```

### Local Execution Mode

If you prefer to run Terraform locally but still use Terraform Cloud for state:

```hcl
# Set execution mode to "local" in workspace settings
# Or via API/CLI
```

In local mode, Terraform Cloud only stores state. Plans and applies run on your machine.

### Terraform Cloud Agents

For organizations that need to access private networks (VPCs, on-premises resources) from Terraform Cloud:

```
Terraform Cloud
      |
      | (TLS tunnel)
      v
TFC Agent (in your VPC)
      |
      v
Private Resources (databases, internal APIs)
```

Agents are lightweight processes that run in your infrastructure and execute Terraform operations on behalf of Terraform Cloud.

---

## Variables and Variable Sets

### Workspace Variables

Set variables for a specific workspace through the UI, API, or CLI:

| Category | Description | Example |
|----------|-------------|---------|
| Terraform Variables | Values for `variable` blocks | `instance_type = "t3.large"` |
| Environment Variables | Shell environment variables | `AWS_ACCESS_KEY_ID = "AKIA..."` |

Mark variables as **sensitive** to prevent their values from being displayed in the UI or API responses.

### Variable Sets

Variable sets apply variables to multiple workspaces, reducing duplication:

```
Variable Set: "AWS Credentials - Production"
  AWS_ACCESS_KEY_ID     = "AKIA..." (sensitive)
  AWS_SECRET_ACCESS_KEY = "..." (sensitive)
  AWS_DEFAULT_REGION    = "us-east-1"

Applied to workspaces:
  - web-app-prod
  - api-service-prod
  - database-prod
```

### Variable Precedence in Terraform Cloud

1. CLI `-var` flag (highest)
2. Workspace-specific variables
3. Variable set variables (lower-priority sets first, then higher)
4. Variable defaults in configuration (lowest)

---

## Sentinel Policies

Sentinel is HashiCorp's policy-as-code framework. It enforces rules before Terraform applies changes.

### Policy Example: Enforce Tags

```python
# policies/enforce-tags.sentinel
import "tfplan/v2" as tfplan

mandatory_tags = ["Environment", "Team", "ManagedBy"]

allEC2Instances = filter tfplan.resource_changes as _, rc {
    rc.type is "aws_instance" and
    (rc.change.actions contains "create" or rc.change.actions contains "update")
}

main = rule {
    all allEC2Instances as _, instance {
        all mandatory_tags as tag {
            instance.change.after.tags contains tag
        }
    }
}
```

### Policy Example: Restrict Instance Types

```python
# policies/restrict-instance-types.sentinel
import "tfplan/v2" as tfplan

allowed_types = ["t3.micro", "t3.small", "t3.medium", "t3.large"]

allEC2Instances = filter tfplan.resource_changes as _, rc {
    rc.type is "aws_instance" and
    (rc.change.actions contains "create" or rc.change.actions contains "update")
}

main = rule {
    all allEC2Instances as _, instance {
        instance.change.after.instance_type in allowed_types
    }
}
```

### Policy Example: Prevent Public S3 Buckets

```python
# policies/no-public-s3.sentinel
import "tfplan/v2" as tfplan

s3Buckets = filter tfplan.resource_changes as _, rc {
    rc.type is "aws_s3_bucket_public_access_block"
}

main = rule {
    all s3Buckets as _, bucket {
        bucket.change.after.block_public_acls is true and
        bucket.change.after.block_public_policy is true and
        bucket.change.after.ignore_public_acls is true and
        bucket.change.after.restrict_public_buckets is true
    }
}
```

### Policy Enforcement Levels

| Level | Behavior |
|-------|----------|
| Advisory | Warn on failure, allow apply |
| Soft Mandatory | Fail, but can be overridden by authorized users |
| Hard Mandatory | Fail, no override possible |

### Policy Sets

Policy sets group policies and apply them to workspaces:

```
Policy Set: "Security Policies"
  Enforcement: hard-mandatory
  Policies:
    - enforce-tags.sentinel
    - restrict-instance-types.sentinel
    - no-public-s3.sentinel
  Applied to: All workspaces tagged "env:prod"
```

---

## Cost Estimation

Terraform Cloud estimates the monthly cost impact of planned changes before apply. This gives teams visibility into the financial impact of infrastructure changes.

### Supported Resources

Cost estimation supports common AWS, Azure, and GCP resources including:

- Compute (EC2, VMs, GCE)
- Storage (S3, Blob, GCS)
- Databases (RDS, Cloud SQL)
- Load balancers (ALB, NLB)
- NAT Gateways

### Cost Estimation Output

```
Cost estimation:

Resources: 3 of 7 estimated
  $188.84/mo +$78.84

+-------------------------------+---------------+-------+-------------+
| Resource                      | Quantity/Unit | Price | Total       |
+-------------------------------+---------------+-------+-------------+
| aws_instance.web (3x)        | 730 hours     | $0.05 | $109.50/mo  |
| aws_db_instance.main         | 730 hours     | $0.07 | $51.10/mo   |
| aws_nat_gateway.main         | 730 hours     | $0.04 | $28.24/mo   |
+-------------------------------+---------------+-------+-------------+

Overall monthly cost will increase by $78.84, from $110.00 to $188.84.
```

### Using Cost Policies

Combine cost estimation with Sentinel to enforce budget limits:

```python
import "tfrun"

main = rule {
    float(tfrun.cost_estimate.delta_monthly_cost) < 500
}
```

---

## Private Registry

Terraform Cloud includes a private registry for sharing modules and providers within your organization.

### Publishing a Module

1. Connect your VCS provider
2. Create a module in the private registry linked to a Git repository
3. The repository must follow the naming convention: `terraform-<PROVIDER>-<NAME>`
4. Tag releases with semantic versions: `v1.0.0`, `v1.1.0`

### Consuming a Private Module

```hcl
module "vpc" {
  source  = "app.terraform.io/my-org/vpc/aws"
  version = "~> 2.0"

  cidr_block = "10.0.0.0/16"
}
```

### No-Code Provisioning

Terraform Cloud offers "no-code" workspaces that let users deploy pre-built modules through a UI without writing any Terraform code. This enables self-service infrastructure for teams that do not write Terraform.

---

## Team Management and RBAC

### Organization-Level Permissions

| Role | Permissions |
|------|------------|
| Owners | Full access to everything |
| Members | Join teams, view workspaces |

### Workspace-Level Permissions

| Permission | Can View | Can Plan | Can Apply | Can Admin |
|-----------|----------|----------|-----------|-----------|
| Read | Yes | No | No | No |
| Plan | Yes | Yes | No | No |
| Write | Yes | Yes | Yes | No |
| Admin | Yes | Yes | Yes | Yes |

### Team Configuration

```
Team: Platform Engineering
  Workspace Access:
    - prod-*: Admin
    - staging-*: Write
    - dev-*: Write

Team: Application Developers
  Workspace Access:
    - dev-*: Write
    - staging-*: Plan
    - prod-*: Read

Team: Security
  Workspace Access:
    - *: Read
  Policy Set Management: Yes
```

### SSO/SAML Integration

Business-tier organizations can configure SSO with:

- Azure Active Directory
- Okta
- OneLogin
- SAML 2.0 compliant providers

---

## Run Triggers and Notifications

### Run Triggers

Chain workspace runs so that applying one workspace triggers a plan in another:

```
networking workspace (apply)
        |
        ├──> compute workspace (triggered plan)
        |
        └──> database workspace (triggered plan)
```

This is useful when infrastructure components depend on each other but are managed in separate workspaces.

### Notifications

Configure notifications for run status changes:

| Destination | Events |
|-------------|--------|
| Slack | Plan complete, apply complete, errored |
| Email | Plan needs approval, apply complete |
| Webhook | All events (for custom integrations) |
| Microsoft Teams | Plan complete, apply complete |

### Webhook Payload

```json
{
  "payload_version": 1,
  "notification_configuration_id": "nc-abc123",
  "run_url": "https://app.terraform.io/app/my-org/workspaces/prod/runs/run-xyz",
  "run_id": "run-xyz",
  "run_message": "Triggered via VCS",
  "run_created_at": "2024-01-15T10:30:00Z",
  "run_created_by": "developer@example.com",
  "workspace_id": "ws-abc123",
  "workspace_name": "prod-networking",
  "organization_name": "my-org",
  "notifications": [
    {
      "message": "Run Planned and Finished",
      "trigger": "run:planning_completed",
      "run_status": "planned"
    }
  ]
}
```

---

## API-Driven Workflows

Terraform Cloud has a comprehensive REST API for automation:

### Trigger a Run via API

```bash
curl -s \
  --header "Authorization: Bearer $TF_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data '{
    "data": {
      "attributes": {
        "message": "Triggered by CI/CD pipeline",
        "auto-apply": false
      },
      "type": "runs",
      "relationships": {
        "workspace": {
          "data": {
            "type": "workspaces",
            "id": "ws-abc123"
          }
        }
      }
    }
  }' \
  "https://app.terraform.io/api/v2/runs"
```

### Upload Configuration via API

For configurations not stored in VCS:

```bash
# Create a tar.gz of the configuration
tar -czf config.tar.gz -C ./terraform .

# Create a configuration version
CV_ID=$(curl -s \
  --header "Authorization: Bearer $TF_TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  --request POST \
  --data '{"data":{"type":"configuration-versions","attributes":{"auto-queue-runs":true}}}' \
  "https://app.terraform.io/api/v2/workspaces/ws-abc123/configuration-versions" \
  | jq -r '.data.attributes."upload-url"')

# Upload the configuration
curl -s \
  --header "Content-Type: application/octet-stream" \
  --request PUT \
  --data-binary @config.tar.gz \
  "$CV_ID"
```

---

## Best Practices

### 1. Use VCS-Driven Workflows for Production

Let Git be the trigger for infrastructure changes. Code review on PRs with speculative plans provides safety and auditability.

### 2. Separate Workspaces by Blast Radius

Do not put all infrastructure in one workspace. Separate networking, compute, and database into distinct workspaces.

### 3. Use Variable Sets for Shared Configuration

AWS credentials, common tags, and organization-wide settings should be in variable sets applied to multiple workspaces.

### 4. Enforce Policies in Production

Use Sentinel policies with hard-mandatory enforcement for production workspaces. Start with advisory mode to observe before enforcing.

### 5. Pin Terraform Versions per Workspace

Prevent unexpected behavior from version upgrades by pinning each workspace to a specific Terraform version.

### 6. Use Run Triggers for Dependency Chains

When workspace B depends on workspace A, use run triggers instead of manual coordination.

### 7. Review Cost Estimates Before Applying

Make cost estimation review part of your workflow, especially for production changes.

### 8. Rotate API Tokens Regularly

Team and user tokens should be rotated on a regular schedule. Use short-lived tokens where possible.

---

## Next Steps

- [Workspaces](workspaces.md) for CLI workspace management
- [Backends](../01-terraform-basics/backends.md) for alternative state storage
- [Security Best Practices](../03-terraform-advanced/security-best-practices.md) for securing Terraform workflows
