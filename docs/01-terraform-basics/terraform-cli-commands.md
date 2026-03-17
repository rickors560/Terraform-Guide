# Terraform CLI Commands

## Table of Contents

- [Command Overview](#command-overview)
- [Core Workflow Commands](#core-workflow-commands)
- [State Management Commands](#state-management-commands)
- [Inspection Commands](#inspection-commands)
- [Utility Commands](#utility-commands)
- [Advanced Commands](#advanced-commands)
- [Environment Variables](#environment-variables)
- [Command Cheat Sheet](#command-cheat-sheet)

---

## Command Overview

Terraform CLI commands follow the pattern:

```
terraform [global-options] <subcommand> [options] [args]
```

Global options apply to all commands:

| Flag | Description |
|------|-------------|
| `-chdir=<path>` | Switch to a different working directory before executing |
| `-help` | Show help for a command |
| `-version` | Show the Terraform version |

---

## Core Workflow Commands

### terraform init

Initializes a working directory containing Terraform configuration files. This is the first command you run for any new or cloned project.

```bash
# Basic initialization
terraform init

# Upgrade providers to the latest allowed versions
terraform init -upgrade

# Reconfigure the backend (prompts for settings)
terraform init -reconfigure

# Migrate state to a new backend
terraform init -migrate-state

# Use a plugin cache directory
terraform init -plugin-dir=/path/to/plugins

# Initialize without accessing remote backends (useful for syntax checking)
terraform init -backend=false
```

What `init` does:

1. Downloads and installs providers specified in `required_providers`
2. Downloads modules referenced by `module` blocks
3. Configures the backend for state storage
4. Creates the `.terraform` directory and `.terraform.lock.hcl` file

### terraform plan

Creates an execution plan showing what changes Terraform will make to reach the desired state.

```bash
# Basic plan
terraform plan

# Save the plan to a file (recommended for CI/CD)
terraform plan -out=tfplan

# Plan for destruction
terraform plan -destroy

# Target specific resources only
terraform plan -target=aws_instance.web
terraform plan -target=module.vpc

# Pass variables inline
terraform plan -var="instance_type=t3.large"
terraform plan -var-file="production.tfvars"

# Set parallelism (default: 10)
terraform plan -parallelism=20

# Skip refresh (faster, but may miss drift)
terraform plan -refresh=false

# Show detailed output including unchanged attributes
terraform plan -detailed-exitcodes
# Exit code 0 = no changes
# Exit code 1 = error
# Exit code 2 = changes present
```

Reading plan output:

```
# Resource actions are indicated with the following symbols:
#   + create
#   - destroy
#   ~ update in-place
#   -/+ destroy and then create replacement
#   +/- create replacement and then destroy (when create_before_destroy is set)
#   <= read (data sources)
```

### terraform apply

Executes the actions proposed in a Terraform plan to create, update, or destroy infrastructure.

```bash
# Apply with interactive approval
terraform apply

# Apply a saved plan file (no approval prompt)
terraform apply tfplan

# Auto-approve (skip interactive confirmation)
terraform apply -auto-approve

# Target specific resources
terraform apply -target=aws_instance.web

# Pass variables
terraform apply -var="instance_type=t3.large"
terraform apply -var-file="production.tfvars"

# Replace a specific resource (force recreation)
terraform apply -replace=aws_instance.web

# Set parallelism
terraform apply -parallelism=30
```

**Best practice for CI/CD pipelines:**

```bash
# Step 1: Generate a plan file
terraform plan -out=tfplan

# Step 2: Review the plan (manual approval gate)

# Step 3: Apply the exact plan
terraform apply tfplan
```

This ensures what was reviewed is exactly what gets applied.

### terraform destroy

Destroys all resources managed by the current Terraform configuration.

```bash
# Destroy with interactive approval
terraform destroy

# Auto-approve destruction
terraform destroy -auto-approve

# Destroy specific resources only
terraform destroy -target=aws_instance.web

# Preview what will be destroyed
terraform plan -destroy
```

**Caution**: `terraform destroy` is irreversible. In production, use state removal (`terraform state rm`) or lifecycle `prevent_destroy` to protect critical resources:

```hcl
resource "aws_rds_instance" "production" {
  # ...
  lifecycle {
    prevent_destroy = true
  }
}
```

---

## State Management Commands

### terraform state list

Lists all resources tracked in the state file:

```bash
terraform state list
# aws_instance.web
# aws_security_group.web
# aws_vpc.main
# module.vpc.aws_subnet.private[0]
# module.vpc.aws_subnet.private[1]

# Filter by resource type or module
terraform state list aws_instance
terraform state list module.vpc
```

### terraform state show

Shows the detailed attributes of a single resource in the state:

```bash
terraform state show aws_instance.web
# resource "aws_instance" "web" {
#     ami                    = "ami-0abcdef1234567890"
#     arn                    = "arn:aws:ec2:us-east-1:123456789012:instance/i-0abc123def456"
#     instance_type          = "t3.micro"
#     id                     = "i-0abc123def456"
#     public_ip              = "54.123.45.67"
#     ...
# }
```

### terraform state mv

Moves a resource in the state. Used for renaming resources or moving them between modules without destroying and recreating:

```bash
# Rename a resource
terraform state mv aws_instance.web aws_instance.app_server

# Move a resource into a module
terraform state mv aws_instance.web module.compute.aws_instance.web

# Move a resource out of a module
terraform state mv module.compute.aws_instance.web aws_instance.web

# Move between modules
terraform state mv module.old.aws_instance.web module.new.aws_instance.web
```

### terraform state rm

Removes a resource from the state without destroying the actual infrastructure. The resource continues to exist but Terraform no longer manages it:

```bash
# Remove a single resource
terraform state rm aws_instance.web

# Remove a module and all its resources
terraform state rm module.vpc

# Dry run (show what would be removed)
terraform state rm -dry-run aws_instance.web
```

### terraform state pull / push

```bash
# Download the current state to stdout
terraform state pull > state_backup.json

# Upload a local state file to the remote backend
terraform state push state_backup.json
# WARNING: state push can overwrite remote state — use with extreme caution
```

---

## Inspection Commands

### terraform show

Displays the current state or a saved plan in human-readable format:

```bash
# Show current state
terraform show

# Show a saved plan
terraform show tfplan

# Output as JSON (useful for programmatic processing)
terraform show -json
terraform show -json tfplan
```

### terraform output

Reads output values from the state file:

```bash
# Show all outputs
terraform output

# Show a specific output
terraform output instance_ip

# Output as JSON
terraform output -json

# Raw value (no quotes, useful for scripting)
terraform output -raw instance_ip

# Use in scripts
INSTANCE_IP=$(terraform output -raw instance_ip)
ssh ec2-user@${INSTANCE_IP}
```

### terraform console

Opens an interactive console for evaluating Terraform expressions:

```bash
terraform console

# In the console:
> var.instance_type
"t3.micro"

> length(var.availability_zones)
3

> cidrsubnet("10.0.0.0/16", 8, 1)
"10.0.1.0/24"

> jsonencode({"key" = "value"})
"{\"key\":\"value\"}"

> [for s in ["a", "b", "c"] : upper(s)]
["A", "B", "C"]

# Exit with Ctrl+D or type exit
```

### terraform graph

Generates a visual representation of the dependency graph in DOT format:

```bash
# Generate the graph
terraform graph

# Create a PNG image (requires Graphviz)
terraform graph | dot -Tpng > graph.png

# Create an SVG
terraform graph | dot -Tsvg > graph.svg

# Plan graph (shows planned changes)
terraform graph -type=plan

# Apply graph
terraform graph -type=apply
```

Install Graphviz to render the graph:

```bash
# Ubuntu/Debian
sudo apt-get install graphviz

# macOS
brew install graphviz
```

### terraform providers

Shows the providers required by the configuration:

```bash
# List required providers
terraform providers

# Show the providers locked in the dependency lock file
terraform providers lock

# Mirror providers to a local directory (for air-gapped environments)
terraform providers mirror /path/to/mirror

# Generate a lock file for multiple platforms
terraform providers lock \
  -platform=linux_amd64 \
  -platform=darwin_amd64 \
  -platform=darwin_arm64
```

---

## Utility Commands

### terraform fmt

Automatically formats Terraform configuration files to the canonical style:

```bash
# Format files in the current directory
terraform fmt

# Recursively format all files in subdirectories
terraform fmt -recursive

# Check if files are formatted (exit code 0 = formatted, 3 = not formatted)
terraform fmt -check

# Show the diff of formatting changes
terraform fmt -diff

# Format and show which files changed
terraform fmt -list=true

# Format a specific file
terraform fmt main.tf
```

**Use in CI/CD:**

```bash
# Fail the pipeline if code is not formatted
terraform fmt -check -recursive
```

### terraform validate

Validates the configuration files for syntax and internal consistency:

```bash
# Validate the current directory
terraform validate

# JSON output
terraform validate -json
```

`validate` checks:

- Syntax correctness
- Attribute names and types
- Required arguments are present
- Internal references are valid

`validate` does NOT check:

- Remote state
- Provider API validity
- Whether resource configurations are actually valid in the cloud

You must run `terraform init` before `terraform validate` so providers are available.

### terraform import

Imports existing infrastructure into Terraform state:

```bash
# Import a resource
terraform import aws_instance.web i-0abc123def456

# Import into a module
terraform import module.vpc.aws_vpc.main vpc-0abc123def456

# Import with a specific index (count)
terraform import 'aws_instance.web[0]' i-0abc123def456

# Import with for_each key
terraform import 'aws_instance.web["app"]' i-0abc123def456

# Import with a specific provider
terraform import -provider=aws.us_west aws_instance.web i-0abc123def456
```

**Terraform 1.5+ import blocks** (declarative import):

```hcl
import {
  to = aws_instance.web
  id = "i-0abc123def456"
}
```

Then run `terraform plan -generate-config-out=generated.tf` to auto-generate the configuration.

### terraform workspace

Manages workspaces (isolated state environments):

```bash
# List workspaces
terraform workspace list

# Create a new workspace
terraform workspace new staging

# Switch to a workspace
terraform workspace select production

# Show current workspace
terraform workspace show

# Delete a workspace (must switch away first)
terraform workspace delete staging
```

### terraform force-unlock

Manually releases a stuck state lock:

```bash
# Unlock with the lock ID from the error message
terraform force-unlock LOCK_ID

# Skip confirmation
terraform force-unlock -force LOCK_ID
```

Only use this when you are certain no other Terraform process is running. Unlocking while another process is active can corrupt state.

---

## Advanced Commands

### terraform taint / untaint (Deprecated)

`taint` was deprecated in Terraform 0.15.2. Use `-replace` instead:

```bash
# Old way (deprecated)
terraform taint aws_instance.web
terraform untaint aws_instance.web

# New way (preferred)
terraform apply -replace=aws_instance.web
```

### terraform refresh (Deprecated as standalone)

`refresh` was deprecated as a standalone command. Use `terraform apply -refresh-only`:

```bash
# Old way (deprecated)
terraform refresh

# New way (preferred) — shows what drift was detected
terraform apply -refresh-only

# Auto-approve refresh
terraform apply -refresh-only -auto-approve
```

### terraform test

Runs test files (`.tftest.hcl`) to validate configurations:

```bash
# Run all tests
terraform test

# Run tests in verbose mode
terraform test -verbose

# Run specific test file
terraform test -filter=tests/basic.tftest.hcl
```

Example test file (`tests/basic.tftest.hcl`):

```hcl
run "verify_bucket_name" {
  command = plan

  assert {
    condition     = aws_s3_bucket.main.bucket == "expected-bucket-name"
    error_message = "Bucket name did not match expected value"
  }
}
```

---

## Environment Variables

Terraform respects several environment variables that control its behavior:

| Variable | Description |
|----------|-------------|
| `TF_LOG` | Enable logging (`TRACE`, `DEBUG`, `INFO`, `WARN`, `ERROR`) |
| `TF_LOG_PATH` | Write logs to a file instead of stderr |
| `TF_INPUT` | Set to `0` or `false` to disable interactive prompts |
| `TF_VAR_<name>` | Set variable values (e.g., `TF_VAR_instance_type=t3.large`) |
| `TF_CLI_ARGS` | Additional arguments for all commands |
| `TF_CLI_ARGS_<command>` | Additional arguments for a specific command |
| `TF_DATA_DIR` | Override the `.terraform` directory location |
| `TF_PLUGIN_CACHE_DIR` | Directory for caching provider plugins |
| `TF_IN_AUTOMATION` | Set to any value to adjust output for automation |

### Debugging

```bash
# Enable trace-level logging
export TF_LOG=TRACE
export TF_LOG_PATH="terraform.log"

# Run your command — logs go to terraform.log
terraform plan

# Disable logging
unset TF_LOG
unset TF_LOG_PATH
```

### CI/CD Environment

```bash
export TF_INPUT=false          # Never prompt for input
export TF_IN_AUTOMATION=true   # Suppress hints about next commands
export TF_CLI_ARGS_plan="-no-color"    # Disable color for log parsers
export TF_CLI_ARGS_apply="-no-color"
```

---

## Command Cheat Sheet

### Daily Workflow

```bash
terraform init                    # Initialize project
terraform fmt -recursive          # Format all files
terraform validate                # Check syntax
terraform plan -out=tfplan        # Preview changes
terraform apply tfplan            # Apply changes
terraform output                  # View outputs
```

### Investigation

```bash
terraform state list              # What does Terraform manage?
terraform state show <resource>   # Show resource details
terraform show                    # Show full state
terraform console                 # Test expressions interactively
terraform graph | dot -Tpng > g.png  # Visualize dependencies
```

### Maintenance

```bash
terraform init -upgrade           # Upgrade providers
terraform apply -refresh-only     # Detect and sync drift
terraform apply -replace=<res>    # Force resource recreation
terraform state mv <old> <new>    # Rename in state
terraform state rm <resource>     # Stop managing a resource
```

### Cleanup

```bash
terraform plan -destroy           # Preview destruction
terraform destroy                 # Destroy all resources
terraform workspace delete <name> # Remove a workspace
```

### CI/CD Pipeline

```bash
terraform init -input=false
terraform fmt -check -recursive
terraform validate
terraform plan -out=tfplan -input=false -detailed-exitcodes
terraform apply -input=false tfplan
```

---

## Next Steps

- [State Management](state-management.md) for deep coverage of state operations
- [Backends](backends.md) for remote state configuration
- [Workspaces](../02-terraform-intermediate/workspaces.md) for environment isolation
