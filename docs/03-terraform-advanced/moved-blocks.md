# Moved Blocks

## Table of Contents

- [What are Moved Blocks](#what-are-moved-blocks)
- [Why Moved Blocks Exist](#why-moved-blocks-exist)
- [Syntax](#syntax)
- [Renaming Resources](#renaming-resources)
- [Moving Resources Between Modules](#moving-resources-between-modules)
- [Moving Modules](#moving-modules)
- [Refactoring count to for_each](#refactoring-count-to-for_each)
- [State Surgery Alternatives](#state-surgery-alternatives)
- [Moved Block Lifecycle](#moved-block-lifecycle)
- [Limitations](#limitations)
- [Best Practices](#best-practices)

---

## What are Moved Blocks

Moved blocks (introduced in Terraform 1.1) let you refactor Terraform configurations without destroying and recreating resources. When you rename a resource, move it into a module, or reorganize your code, a `moved` block tells Terraform that the resource at the old address is the same resource at the new address.

Without moved blocks, renaming `aws_instance.web` to `aws_instance.application` would cause Terraform to destroy the old instance and create a new one. With a moved block, Terraform updates the state to reflect the new name without touching the infrastructure.

```hcl
moved {
  from = aws_instance.web
  to   = aws_instance.application
}
```

---

## Why Moved Blocks Exist

Before moved blocks, the only way to rename or reorganize resources was:

1. **`terraform state mv`**: A manual, imperative command that modifies state directly. Risky, not reviewable, and must be coordinated across the team.

2. **Destroy and recreate**: Terraform destroys the old-named resource and creates a new one. Unacceptable for stateful resources like databases.

Moved blocks solve these problems by being:

- **Declarative**: Part of the configuration, not a manual command
- **Reviewable**: Shows up in pull requests and code review
- **Safe**: Terraform validates the move during plan
- **Collaborative**: Team members get the state update automatically on their next plan

---

## Syntax

```hcl
moved {
  from = <old_resource_address>
  to   = <new_resource_address>
}
```

Both `from` and `to` use Terraform resource addresses. The moved block can appear in any `.tf` file in the module.

---

## Renaming Resources

### Simple Rename

```hcl
# Before: resource was named "web"
# resource "aws_instance" "web" { ... }

# After: renamed to "application"
resource "aws_instance" "application" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
}

moved {
  from = aws_instance.web
  to   = aws_instance.application
}
```

Running `terraform plan` shows:

```
# aws_instance.web has moved to aws_instance.application
```

No destroy, no create. Just a state update.

### Renaming with count

```hcl
# Before
# resource "aws_instance" "server" {
#   count = 3
# }

# After: renamed
resource "aws_instance" "app_server" {
  count = 3
  # ...
}

moved {
  from = aws_instance.server
  to   = aws_instance.app_server
}
```

This moves all indexed instances (`server[0]`, `server[1]`, `server[2]`) to their corresponding new addresses.

### Renaming with for_each

```hcl
# Before
# resource "aws_instance" "nodes" {
#   for_each = toset(["a", "b", "c"])
# }

# After: renamed
resource "aws_instance" "cluster_nodes" {
  for_each = toset(["a", "b", "c"])
  # ...
}

moved {
  from = aws_instance.nodes
  to   = aws_instance.cluster_nodes
}
```

---

## Moving Resources Between Modules

### Moving a Resource Into a Module

```hcl
# Before: resource was in the root module
# resource "aws_vpc.main" { ... }

# After: moved into a "networking" module
module "networking" {
  source = "./modules/networking"
  # ...
}

moved {
  from = aws_vpc.main
  to   = module.networking.aws_vpc.main
}
```

Inside the module (`modules/networking/main.tf`):

```hcl
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
}
```

### Moving a Resource Out of a Module

```hcl
# Before: resource was inside module.networking
# module "networking" { ... }

# After: resource is now in the root module
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

moved {
  from = module.networking.aws_vpc.main
  to   = aws_vpc.main
}
```

### Moving Between Modules

```hcl
moved {
  from = module.old_module.aws_instance.app
  to   = module.new_module.aws_instance.app
}
```

### Moving a Resource Into a Nested Module

```hcl
moved {
  from = aws_s3_bucket.logs
  to   = module.monitoring.module.logging.aws_s3_bucket.main
}
```

---

## Moving Modules

### Renaming a Module

```hcl
# Before
# module "web_servers" {
#   source = "./modules/compute"
# }

# After: renamed
module "application_servers" {
  source = "./modules/compute"
}

moved {
  from = module.web_servers
  to   = module.application_servers
}
```

This moves all resources within the module. If the module contains `aws_instance.web`, `aws_security_group.web`, and `aws_eip.web`, all three are moved automatically.

### Moving a Module Into a Parent Module

```hcl
moved {
  from = module.vpc
  to   = module.infrastructure.module.vpc
}
```

---

## Refactoring count to for_each

One of the most common refactoring scenarios is changing from `count` to `for_each`. This requires individual moved blocks for each instance.

### Example: count to for_each

```hcl
# Before
# resource "aws_instance" "web" {
#   count         = 3
#   ami           = var.ami_id
#   instance_type = "t3.micro"
# }

# After: using for_each with named keys
resource "aws_instance" "web" {
  for_each = {
    app    = "t3.micro"
    api    = "t3.small"
    worker = "t3.medium"
  }

  ami           = var.ami_id
  instance_type = each.value
}

# Map each old index to the new key
moved {
  from = aws_instance.web[0]
  to   = aws_instance.web["app"]
}

moved {
  from = aws_instance.web[1]
  to   = aws_instance.web["api"]
}

moved {
  from = aws_instance.web[2]
  to   = aws_instance.web["worker"]
}
```

### Example: for_each Key Rename

```hcl
# Before: for_each used environment names
# resource "aws_s3_bucket" "env" {
#   for_each = toset(["dev", "stg", "prd"])
# }

# After: using full names
resource "aws_s3_bucket" "env" {
  for_each = toset(["development", "staging", "production"])
  bucket   = "myapp-${each.key}-data"
}

moved {
  from = aws_s3_bucket.env["dev"]
  to   = aws_s3_bucket.env["development"]
}

moved {
  from = aws_s3_bucket.env["stg"]
  to   = aws_s3_bucket.env["staging"]
}

moved {
  from = aws_s3_bucket.env["prd"]
  to   = aws_s3_bucket.env["production"]
}
```

---

## State Surgery Alternatives

Moved blocks are the preferred approach, but `terraform state mv` still has use cases:

### When to Use moved Blocks

- Renaming resources within the same configuration
- Moving resources between modules in the same configuration
- Refactoring count to for_each
- Any change that can be expressed declaratively

### When to Use terraform state mv

- Moving resources between completely separate Terraform configurations (different state files)
- Emergency state repairs
- One-off migrations that do not need to be reproducible

```bash
# Move between state files
terraform state mv -state=old.tfstate -state-out=new.tfstate \
  aws_instance.web aws_instance.web

# Move within the same state (equivalent to moved block)
terraform state mv aws_instance.web aws_instance.application
```

### Comparison

| Feature | moved block | terraform state mv |
|---------|-------------|-------------------|
| Declarative | Yes | No (imperative) |
| Reviewable | Yes (in PRs) | No |
| Repeatable | Yes | No (one-time) |
| Cross-state | No | Yes |
| Team coordination | Automatic | Manual |
| Rollback | Remove the block | Complex |

---

## Moved Block Lifecycle

### When to Add Moved Blocks

Add a moved block at the same time you rename or reorganize a resource. Include it in the same commit/PR as the refactoring.

### When to Remove Moved Blocks

Moved blocks can be removed after all team members and CI/CD pipelines have applied the change. A safe approach:

1. Add the moved block and refactor the resource (PR #1)
2. Wait for all environments to apply successfully
3. Remove the moved block in a follow-up (PR #2)

**What happens if you remove a moved block too early?**

If someone runs `terraform plan` with an older state that still has the old address, Terraform will plan to destroy the old-named resource and create a new one. This is why you should wait until all states have been updated.

### Chaining Moved Blocks

If a resource has been renamed multiple times, you can chain moved blocks:

```hcl
# Rename history: server -> web -> application
moved {
  from = aws_instance.server
  to   = aws_instance.web
}

moved {
  from = aws_instance.web
  to   = aws_instance.application
}

resource "aws_instance" "application" {
  # ...
}
```

Terraform follows the chain: `server -> web -> application`.

---

## Limitations

### 1. Cannot Move Across State Files

Moved blocks only work within a single Terraform configuration (single state file). To move resources between configurations, use `terraform state mv` with `-state` and `-state-out` flags.

### 2. Cannot Change Resource Type

You cannot use moved blocks to change a resource from one type to another:

```hcl
# This does NOT work
moved {
  from = aws_instance.web
  to   = aws_ec2_instance.web    # Different resource type
}
```

### 3. Cannot Move Data Sources

Moved blocks only apply to managed resources and modules, not data sources.

### 4. Provider Must Support It

The resource's provider must support the state migration. Most providers handle this correctly, but edge cases exist.

### 5. Cannot Move Between Providers

```hcl
# This does NOT work
moved {
  from = aws_instance.web           # AWS provider
  to   = google_compute_instance.web  # Google provider
}
```

---

## Best Practices

### 1. Always Use Moved Blocks for Refactoring

Never rely on `terraform state mv` for changes that can be expressed as moved blocks. Moved blocks are safer, reviewable, and team-friendly.

### 2. Verify with Plan Before Apply

```bash
terraform plan
# aws_instance.web has moved to aws_instance.application
# No other changes.
```

Ensure the plan shows only the move and no unexpected creates or destroys.

### 3. Include Moved Blocks in the Same PR

The refactoring and the moved block should be in the same commit. This ensures the change is atomic and reviewable.

### 4. Document the Reason

Add a comment explaining why the move was necessary:

```hcl
# Renamed to match our naming convention (APP-1234)
moved {
  from = aws_instance.web
  to   = aws_instance.application
}
```

### 5. Remove Moved Blocks Eventually

Moved blocks are transitional. Remove them after all states have been updated to reduce configuration clutter. A good rule of thumb: keep them for 2-4 weeks after the change is applied everywhere.

### 6. Test Moves with Plan

Before applying, verify the move produces no infrastructure changes:

```bash
terraform plan
# Only state changes, no resource changes
```

### 7. Combine with Import Blocks

When importing existing resources and reorganizing at the same time, use both import and moved blocks:

```hcl
# Import the existing resource
import {
  to = aws_vpc.legacy
  id = "vpc-0abc123"
}

# Then rename it
moved {
  from = aws_vpc.legacy
  to   = module.networking.aws_vpc.main
}
```

---

## Next Steps

- [Import Existing Infrastructure](import-existing.md) for bringing resources into Terraform
- [State Management](../01-terraform-basics/state-management.md) for state manipulation commands
- [Modules](../02-terraform-intermediate/modules.md) for module organization patterns
