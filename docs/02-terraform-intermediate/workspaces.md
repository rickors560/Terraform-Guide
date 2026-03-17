# Workspaces

## Table of Contents

- [What are Workspaces](#what-are-workspaces)
- [CLI Commands](#cli-commands)
- [Workspace-Based Configurations](#workspace-based-configurations)
- [Workspaces vs Directories](#workspaces-vs-directories)
- [When to Use Workspaces](#when-to-use-workspaces)
- [When NOT to Use Workspaces](#when-not-to-use-workspaces)
- [Workspace Strategies](#workspace-strategies)
- [Workspaces with Remote Backends](#workspaces-with-remote-backends)
- [Terraform Cloud Workspaces](#terraform-cloud-workspaces)
- [Best Practices](#best-practices)

---

## What are Workspaces

Workspaces allow you to manage multiple distinct sets of infrastructure state from a single Terraform configuration. Each workspace has its own state file, enabling you to create parallel environments (dev, staging, production) without duplicating configuration code.

When you initialize a Terraform project, you start in the `default` workspace. Each additional workspace you create gets its own isolated state file.

### How State is Stored Per Workspace

**Local backend:**

```
terraform.tfstate.d/
  dev/
    terraform.tfstate
  staging/
    terraform.tfstate
  production/
    terraform.tfstate
terraform.tfstate              # default workspace
```

**S3 backend:**

```
s3://my-state-bucket/
  env:/dev/terraform.tfstate
  env:/staging/terraform.tfstate
  env:/production/terraform.tfstate
  terraform.tfstate              # default workspace
```

---

## CLI Commands

### List Workspaces

```bash
terraform workspace list
# * default
#   dev
#   staging
#   production
```

The `*` indicates the currently selected workspace.

### Create a Workspace

```bash
terraform workspace new dev
# Created and switched to workspace "dev"!

terraform workspace new staging
terraform workspace new production
```

### Select a Workspace

```bash
terraform workspace select dev
# Switched to workspace "dev".

terraform workspace select production
```

### Show Current Workspace

```bash
terraform workspace show
# dev
```

### Delete a Workspace

```bash
# Must switch to a different workspace first
terraform workspace select default

# Delete the workspace (state must be empty)
terraform workspace delete dev

# Force delete (even if state is not empty)
terraform workspace delete -force dev
```

---

## Workspace-Based Configurations

### Using terraform.workspace

The `terraform.workspace` expression returns the name of the current workspace:

```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = lookup(var.instance_types, terraform.workspace, "t3.micro")

  tags = {
    Name        = "web-${terraform.workspace}"
    Environment = terraform.workspace
  }
}
```

### Workspace-Specific Variables

```hcl
variable "instance_types" {
  type = map(string)
  default = {
    dev        = "t3.micro"
    staging    = "t3.small"
    production = "t3.large"
  }
}

variable "instance_counts" {
  type = map(number)
  default = {
    dev        = 1
    staging    = 2
    production = 3
  }
}

variable "enable_monitoring" {
  type = map(bool)
  default = {
    dev        = false
    staging    = true
    production = true
  }
}

locals {
  instance_type    = lookup(var.instance_types, terraform.workspace, "t3.micro")
  instance_count   = lookup(var.instance_counts, terraform.workspace, 1)
  monitoring       = lookup(var.enable_monitoring, terraform.workspace, false)
}

resource "aws_instance" "web" {
  count         = local.instance_count
  ami           = var.ami_id
  instance_type = local.instance_type
  monitoring    = local.monitoring

  tags = {
    Name        = "web-${terraform.workspace}-${count.index}"
    Environment = terraform.workspace
  }
}
```

### Workspace-Specific CIDR Blocks

```hcl
locals {
  vpc_cidrs = {
    dev        = "10.0.0.0/16"
    staging    = "10.1.0.0/16"
    production = "10.2.0.0/16"
  }

  vpc_cidr = lookup(local.vpc_cidrs, terraform.workspace, "10.0.0.0/16")
}

resource "aws_vpc" "main" {
  cidr_block = local.vpc_cidr

  tags = {
    Name        = "vpc-${terraform.workspace}"
    Environment = terraform.workspace
  }
}
```

### Workspace-Specific Variable Files

Instead of embedding all environment differences in maps, use workspace-specific variable files:

```
envs/
  dev.tfvars
  staging.tfvars
  production.tfvars
```

```bash
terraform workspace select dev
terraform apply -var-file="envs/$(terraform workspace show).tfvars"
```

Or in a Makefile:

```makefile
plan:
	terraform workspace select $(ENV)
	terraform plan -var-file="envs/$(ENV).tfvars"

apply:
	terraform workspace select $(ENV)
	terraform apply -var-file="envs/$(ENV).tfvars"
```

```bash
make plan ENV=production
make apply ENV=production
```

---

## Workspaces vs Directories

There are two main approaches to managing multiple environments:

### Approach 1: Workspaces (Single Codebase)

```
infrastructure/
  main.tf
  variables.tf
  outputs.tf
  envs/
    dev.tfvars
    staging.tfvars
    production.tfvars
```

All environments share the exact same code. Differences are captured in variable files and `terraform.workspace` conditionals.

**Pros:**

- DRY (Don't Repeat Yourself) — one copy of the code
- Changes propagate to all environments
- Less code to maintain

**Cons:**

- All environments must have the same resource structure
- Hard to make one environment different (e.g., dev needs a bastion, prod does not)
- Risk of accidentally applying to the wrong workspace
- Cannot use different Terraform versions per environment

### Approach 2: Directories (Separate Codebases)

```
environments/
  dev/
    main.tf
    variables.tf
    terraform.tfvars
    backend.hcl
  staging/
    main.tf
    variables.tf
    terraform.tfvars
    backend.hcl
  production/
    main.tf
    variables.tf
    terraform.tfvars
    backend.hcl
modules/
  vpc/
  compute/
  database/
```

Each environment has its own directory with its own state, calling shared modules.

**Pros:**

- Each environment can have different resources
- No risk of accidentally applying to the wrong environment
- Can use different module versions per environment
- Clearer blast radius
- Easier to understand what exists in each environment

**Cons:**

- Some code duplication (module calls)
- Must update each environment separately

### Recommendation

For production systems, **separate directories with shared modules** is the safer and more flexible approach. Use workspaces for truly identical environments (e.g., ephemeral feature-branch environments) where structural differences are not needed.

---

## When to Use Workspaces

Workspaces work well when:

- **Environments are structurally identical**: Same resources, same architecture, only parameter differences (instance size, count, CIDR blocks)
- **Ephemeral environments**: Feature-branch environments, review apps, temporary testing environments
- **Multi-tenant SaaS**: Same infrastructure for different customers
- **Blue/green deployments**: Switching between two identical environments

### Example: Feature Branch Environments

```bash
# Developer creates a feature branch environment
terraform workspace new feature-auth-v2
terraform apply -var-file="envs/dev.tfvars"

# Test the feature...

# Clean up
terraform destroy -auto-approve
terraform workspace select default
terraform workspace delete feature-auth-v2
```

### Example: Multi-Tenant

```hcl
locals {
  tenant_config = {
    acme_corp = {
      instance_type = "t3.large"
      db_class      = "db.r5.large"
    }
    small_biz = {
      instance_type = "t3.micro"
      db_class      = "db.t3.micro"
    }
  }

  config = local.tenant_config[terraform.workspace]
}
```

---

## When NOT to Use Workspaces

Avoid workspaces when:

- **Environments need different resources**: Production needs a WAF, dev does not
- **You need different Terraform versions**: Each workspace uses the same binary
- **Different teams manage different environments**: Workspaces share the same backend access
- **You need strict isolation**: A mistake in workspace selection can destroy production
- **Environments use different AWS accounts**: While possible with provider configuration, it is error-prone

---

## Workspace Strategies

### Strategy 1: Environment-Per-Workspace

```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

Simple and common. Works when all environments are identical.

### Strategy 2: Region-Per-Workspace

```hcl
locals {
  region_config = {
    us-east-1 = { ami = "ami-east-123" }
    eu-west-1 = { ami = "ami-west-456" }
  }
}

provider "aws" {
  region = terraform.workspace
}
```

### Strategy 3: Combined Environment and Component

```bash
terraform workspace new prod-web
terraform workspace new prod-api
terraform workspace new dev-web
terraform workspace new dev-api
```

This gets complex quickly. Prefer separate directories at this level.

---

## Workspaces with Remote Backends

### S3 Backend

```hcl
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
```

Workspace state files are stored under `env:/<workspace-name>/<key>`:

```
s3://mycompany-terraform-state/
  infrastructure/terraform.tfstate                      # default
  env:/dev/infrastructure/terraform.tfstate             # dev
  env:/staging/infrastructure/terraform.tfstate         # staging
  env:/production/infrastructure/terraform.tfstate      # production
```

### Consul Backend

```hcl
terraform {
  backend "consul" {
    address = "consul.example.com:8500"
    path    = "terraform/infrastructure"
  }
}
```

State is stored at `<path>-<workspace>`:

```
terraform/infrastructure              # default
terraform/infrastructure-dev          # dev
terraform/infrastructure-production   # production
```

---

## Terraform Cloud Workspaces

Terraform Cloud workspaces are fundamentally different from CLI workspaces. In Terraform Cloud, each workspace is a completely independent configuration with its own:

- State file
- Variables
- Run history
- VCS connection
- Team permissions

### CLI Workspaces vs Terraform Cloud Workspaces

| Feature | CLI Workspaces | Terraform Cloud Workspaces |
|---------|---------------|---------------------------|
| Configuration | Shared (same .tf files) | Independent (can differ) |
| Variables | Shared declarations | Independent per workspace |
| State | Same backend, different keys | Fully isolated |
| Permissions | Same access | Per-workspace RBAC |
| VCS | Not applicable | Per-workspace VCS connection |
| Runs | Local execution | Remote execution |

### Terraform Cloud Workspace Configuration

```hcl
terraform {
  cloud {
    organization = "my-org"

    workspaces {
      # Single workspace
      name = "prod-networking"

      # OR workspace by tags (select at runtime)
      # tags = ["prod", "networking"]
    }
  }
}
```

### Workspace Tags

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

```bash
# Select from tagged workspaces
terraform workspace select prod-web
```

---

## Best Practices

### 1. Never Use the Default Workspace for Real Infrastructure

The default workspace cannot be deleted and does not have an obvious name. Always create named workspaces:

```bash
terraform workspace new dev       # instead of using "default"
```

### 2. Use Workspace-Aware Resource Naming

Prevent naming collisions across workspaces:

```hcl
resource "aws_s3_bucket" "data" {
  bucket = "myapp-${terraform.workspace}-data"
}

resource "aws_instance" "web" {
  tags = {
    Name = "web-${terraform.workspace}"
  }
}
```

### 3. Protect Production Workspaces

Add safeguards to prevent accidental destruction of production:

```hcl
resource "aws_db_instance" "main" {
  # ...

  deletion_protection = terraform.workspace == "production"

  lifecycle {
    prevent_destroy = true
  }
}
```

### 4. Use CI/CD to Enforce Workspace Selection

Never rely on humans to select the correct workspace. CI/CD pipelines should explicitly select the workspace:

```yaml
# GitHub Actions
- name: Terraform Apply
  run: |
    terraform workspace select ${{ env.ENVIRONMENT }}
    terraform apply -auto-approve -var-file="envs/${{ env.ENVIRONMENT }}.tfvars"
```

### 5. Document Which Workspaces Exist

Maintain a record of active workspaces and their purpose:

```bash
# List all workspaces
terraform workspace list

# Check current workspace before any operation
terraform workspace show
```

### 6. Clean Up Unused Workspaces

Ephemeral workspaces (feature branches) should be destroyed and deleted when no longer needed:

```bash
terraform workspace select feature-xyz
terraform destroy -auto-approve
terraform workspace select default
terraform workspace delete feature-xyz
```

### 7. Prefer Directories for Structurally Different Environments

If dev and prod have different resources, use separate directories. Workspaces are for environments with identical structure.

---

## Next Steps

- [Backends](../01-terraform-basics/backends.md) for how workspace state is stored
- [Terraform Cloud](terraform-cloud.md) for Terraform Cloud workspaces
- [State Management](../01-terraform-basics/state-management.md) for managing state across workspaces
