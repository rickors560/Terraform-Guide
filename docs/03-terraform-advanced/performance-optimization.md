# Performance Optimization

## Table of Contents

- [Understanding Terraform Performance](#understanding-terraform-performance)
- [Parallelism](#parallelism)
- [Refresh Optimization](#refresh-optimization)
- [Targeted Operations](#targeted-operations)
- [State File Size Management](#state-file-size-management)
- [Provider Caching](#provider-caching)
- [Module Caching](#module-caching)
- [Plan File Usage](#plan-file-usage)
- [Configuration Optimization](#configuration-optimization)
- [CI/CD Pipeline Optimization](#cicd-pipeline-optimization)
- [Monitoring and Profiling](#monitoring-and-profiling)
- [Best Practices Summary](#best-practices-summary)

---

## Understanding Terraform Performance

Terraform performance is affected by several factors:

```
terraform plan timeline:
|-- Init --|-- Refresh --|-- Diff --|-- Display --|
   10%         60%          20%         10%
```

The refresh phase (reading current state from cloud APIs) typically dominates execution time. For a configuration with 500 resources, Terraform makes 500+ API calls during refresh alone.

Key bottlenecks:

| Bottleneck | Impact | Solution |
|------------|--------|----------|
| API calls during refresh | Slow plan/apply | `-refresh=false`, smaller state files |
| Sequential dependency chains | Cannot parallelize | Flatten dependency graph |
| Large state files | Slow state operations | Split into components |
| Provider downloads | Slow init | Plugin cache |
| Network latency | Slow API responses | Use regions close to your CI/CD runners |

---

## Parallelism

Terraform creates and modifies independent resources in parallel. The default parallelism is 10 concurrent operations.

### Adjusting Parallelism

```bash
# Increase parallelism for faster applies (if API rate limits allow)
terraform apply -parallelism=20

# Decrease parallelism to avoid API throttling
terraform apply -parallelism=5

# Set via environment variable
export TF_CLI_ARGS_apply="-parallelism=20"
export TF_CLI_ARGS_plan="-parallelism=20"
```

### When to Increase Parallelism

- Your configuration has many independent resources
- The cloud provider's API can handle higher request rates
- You are not hitting rate limits

### When to Decrease Parallelism

- You encounter `ThrottlingException` or `Rate exceeded` errors from AWS
- API calls are failing intermittently
- Your account has lower rate limits (new accounts, GovCloud)

### AWS API Rate Limits

AWS applies rate limits per API action per account per region. Common limits:

| Service | Typical Rate Limit |
|---------|-------------------|
| EC2 DescribeInstances | 100 requests/sec |
| S3 PutObject | 3,500 PUTs/sec per prefix |
| IAM operations | 15 requests/sec |
| CloudFormation | 1 request/sec |
| RDS operations | Variable |

If you see throttling errors, reduce parallelism:

```bash
terraform apply -parallelism=5
```

### How Dependencies Affect Parallelism

Parallelism only helps with independent resources. A linear dependency chain is always sequential:

```
# Sequential (each depends on the previous)
VPC -> Subnet -> Route Table -> NAT Gateway -> Instance
# Time: sum of all creation times

# Parallel (all depend only on VPC)
VPC -> Subnet A
VPC -> Subnet B   # These three run in parallel
VPC -> Subnet C
# Time: VPC creation + max(Subnet A, B, C)
```

---

## Refresh Optimization

### Skip Refresh Entirely

```bash
terraform plan -refresh=false
terraform apply -refresh=false
```

This skips all API calls to check current resource state. Terraform trusts the state file is accurate. Use this when:

- You just applied and need to re-run plan
- You are only making changes to a few resources and trust the rest
- Speed is critical in CI/CD

**Risk**: If someone changed a resource outside Terraform, the plan will not detect the drift.

### Refresh-Only Mode

Update state without making changes:

```bash
terraform apply -refresh-only
```

Run this periodically to sync state with reality, then use `-refresh=false` for subsequent plans.

### Targeted Refresh

Combine `-refresh=false` with `-target` to refresh only specific resources:

```bash
# Only refresh and plan for the web instances
terraform plan -target=aws_instance.web -refresh=true
```

---

## Targeted Operations

Target specific resources to avoid processing the entire configuration:

```bash
# Plan only for a specific resource
terraform plan -target=aws_instance.web

# Apply only a specific module
terraform apply -target=module.database

# Multiple targets
terraform plan -target=aws_instance.web -target=aws_security_group.web

# Target all resources of a type
terraform plan -target=aws_instance.web[0]
```

### When to Use -target

- **Debugging**: Isolate a problematic resource
- **Emergency fixes**: Apply a critical change without processing everything
- **Large configurations**: Speed up development iteration
- **Dependency testing**: Verify a specific resource chain

### When NOT to Use -target

- **Production applies**: Always apply the full configuration to catch all changes
- **CI/CD pipelines**: Targeted applies can leave configurations in inconsistent states
- **Regular workflow**: If you need `-target` regularly, your configuration may need to be split

**Warning**: Targeted applies can create state inconsistencies. Always run a full plan afterward to verify.

---

## State File Size Management

Large state files slow down every Terraform operation because the entire file must be read, parsed, and (for remote backends) transmitted over the network.

### Symptoms of State File Size Problems

- `terraform plan` takes minutes even with `-refresh=false`
- `terraform state list` is slow
- State lock timeout errors (large files take longer to read/write)
- Backend storage costs increasing

### Measuring State Size

```bash
# Local state
ls -lh terraform.tfstate
wc -l terraform.tfstate

# Remote state
terraform state pull | wc -c
terraform state pull | jq '.resources | length'

# Count by resource type
terraform state pull | jq '[.resources[].type] | group_by(.) | map({type: .[0], count: length}) | sort_by(-.count)'
```

### Strategies to Reduce State Size

#### 1. Split Into Smaller Configurations

```
# Instead of one giant configuration:
everything/
  main.tf (500 resources)

# Split by component:
networking/     (50 resources)
compute/        (100 resources)
database/       (30 resources)
monitoring/     (80 resources)
iam/            (40 resources)
```

Each directory has its own state file. Use `terraform_remote_state` or data sources to share information.

#### 2. Remove Unused Resources from State

```bash
# Find resources that are no longer in the config
terraform plan
# Resources with "destroy" actions may be removable

# Remove from state (resource continues to exist, just unmanaged)
terraform state rm aws_cloudwatch_log_group.old
```

#### 3. Avoid Storing Large Data in State

Some resources store large amounts of data in state (e.g., `aws_lambda_function` with inline code). Use external references instead:

```hcl
# Bad: stores entire zip in state
resource "aws_lambda_function" "api" {
  filename = "lambda.zip"
  # ...
}

# Better: reference S3 (smaller state entry)
resource "aws_lambda_function" "api" {
  s3_bucket = aws_s3_bucket.lambda_code.id
  s3_key    = "lambda.zip"
  # ...
}
```

---

## Provider Caching

Provider binaries can be large (100MB+ for the AWS provider). Downloading them on every `terraform init` is slow, especially in CI/CD.

### Plugin Cache Directory

```bash
# Set the cache directory
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
mkdir -p "$TF_PLUGIN_CACHE_DIR"
```

Or in `~/.terraformrc`:

```hcl
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
```

### How It Works

1. First `terraform init`: Downloads provider to cache, creates symlinks in `.terraform`
2. Subsequent `terraform init` (same or different project): Uses cached binary, no download

### CI/CD Provider Caching

#### GitHub Actions

```yaml
- name: Cache Terraform providers
  uses: actions/cache@v4
  with:
    path: ~/.terraform.d/plugin-cache
    key: terraform-providers-${{ hashFiles('**/.terraform.lock.hcl') }}
    restore-keys: |
      terraform-providers-

- name: Terraform Init
  run: terraform init
  env:
    TF_PLUGIN_CACHE_DIR: ~/.terraform.d/plugin-cache
```

#### GitLab CI

```yaml
cache:
  key: terraform-providers
  paths:
    - .terraform.d/plugin-cache/

variables:
  TF_PLUGIN_CACHE_DIR: "$CI_PROJECT_DIR/.terraform.d/plugin-cache"
```

### Air-Gapped Environments

Pre-download providers and use a filesystem mirror:

```bash
# Mirror providers
terraform providers mirror /opt/terraform-providers

# Configure the CLI
cat > ~/.terraformrc <<EOF
provider_installation {
  filesystem_mirror {
    path    = "/opt/terraform-providers"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
EOF
```

---

## Module Caching

### Registry Module Caching

Terraform downloads registry modules to `.terraform/modules/`. Unlike providers, there is no built-in module cache across projects.

### CI/CD Module Caching

Cache the `.terraform` directory to avoid re-downloading modules:

```yaml
# GitHub Actions
- name: Cache Terraform modules
  uses: actions/cache@v4
  with:
    path: |
      .terraform/modules
      .terraform/providers
    key: terraform-${{ hashFiles('**/.terraform.lock.hcl', '**/*.tf') }}
```

### Git Module Optimization

For Git-sourced modules, Terraform clones the repository on each init. Speed this up by:

1. Using shallow clones (Terraform does this automatically for tagged refs)
2. Hosting modules in a registry instead of raw Git
3. Vendoring modules locally for frequently used ones

---

## Plan File Usage

### Save and Apply Plan Files

```bash
# Save the plan
terraform plan -out=tfplan

# Apply the exact plan (no re-computation)
terraform apply tfplan
```

### Benefits

1. **Speed**: The apply phase does not need to recompute the plan
2. **Safety**: What was reviewed is exactly what gets applied
3. **Atomicity**: No changes between plan and apply can cause surprises

### CI/CD Pipeline Pattern

```bash
# Stage 1: Plan
terraform plan -out=tfplan -input=false
# Store tfplan as an artifact

# Stage 2: Apply (after approval)
terraform apply -input=false tfplan
```

### Plan File as JSON

```bash
# Convert plan to JSON for programmatic analysis
terraform show -json tfplan > plan.json

# Analyze the plan
cat plan.json | jq '.resource_changes | length'
cat plan.json | jq '[.resource_changes[].change.actions[]] | group_by(.) | map({action: .[0], count: length})'
```

---

## Configuration Optimization

### Reduce Provider Calls with Data Source Consolidation

```hcl
# Bad: multiple data source calls for the same information
data "aws_vpc" "main" { id = var.vpc_id }
data "aws_vpc" "for_subnets" { id = var.vpc_id }
data "aws_vpc" "for_security" { id = var.vpc_id }

# Good: single data source, reference everywhere
data "aws_vpc" "main" { id = var.vpc_id }
# Use data.aws_vpc.main everywhere
```

### Minimize count/for_each with Large Sets

```hcl
# Slow: 1000 security group rules processed individually
resource "aws_security_group_rule" "rules" {
  count = length(var.ip_whitelist)   # 1000 IPs
  # ...
}

# Faster: use cidr_blocks list in fewer rules
resource "aws_security_group_rule" "whitelist" {
  cidr_blocks = var.ip_whitelist     # All IPs in one rule (if same port/protocol)
  # ...
}
```

### Use Locals for Repeated Computations

```hcl
# Bad: repeated computation
resource "aws_instance" "web" {
  tags = {
    Name = "${var.project}-${var.environment}-web"
    Env  = var.environment
  }
}

resource "aws_instance" "api" {
  tags = {
    Name = "${var.project}-${var.environment}-api"
    Env  = var.environment
  }
}

# Good: compute once in locals
locals {
  name_prefix = "${var.project}-${var.environment}"
  common_tags = {
    Env       = var.environment
    ManagedBy = "terraform"
  }
}

resource "aws_instance" "web" {
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-web" })
}
```

---

## CI/CD Pipeline Optimization

### Parallel Module Testing

Test multiple modules in parallel:

```yaml
# GitHub Actions matrix strategy
jobs:
  test:
    strategy:
      matrix:
        module: [vpc, compute, database, monitoring]
    steps:
      - uses: actions/checkout@v4
      - run: |
          cd modules/${{ matrix.module }}
          terraform init
          terraform validate
          terraform test
```

### Skip Unchanged Modules

Only run Terraform for modules with changed files:

```yaml
- name: Get changed files
  id: changed
  uses: tj-actions/changed-files@v42
  with:
    files: modules/**

- name: Terraform Plan
  if: steps.changed.outputs.any_changed == 'true'
  run: terraform plan
```

### Warm Cache in Init Stage

```yaml
jobs:
  init:
    steps:
      - run: terraform init
      - uses: actions/cache/save@v4
        with:
          path: .terraform
          key: tf-init-${{ hashFiles('.terraform.lock.hcl') }}

  plan:
    needs: init
    steps:
      - uses: actions/cache/restore@v4
        with:
          path: .terraform
          key: tf-init-${{ hashFiles('.terraform.lock.hcl') }}
      - run: terraform plan
```

---

## Monitoring and Profiling

### Enable Timing Output

```bash
export TF_LOG=INFO
time terraform plan 2>&1 | tee plan.log
```

### Trace-Level Logging

```bash
export TF_LOG=TRACE
export TF_LOG_PATH=trace.log
terraform plan
# Analyze the log for slow operations
grep "duration" trace.log | sort -t= -k2 -rn | head -20
```

### Measure Plan Duration

```bash
# Simple timing
time terraform plan -refresh=false   # Without refresh
time terraform plan                   # With refresh
# Compare to identify refresh overhead
```

### Profile State Operations

```bash
time terraform state list | wc -l          # How many resources?
time terraform state pull | wc -c          # How big is the state?
time terraform state pull > /dev/null      # Network transfer time
```

---

## Best Practices Summary

| Optimization | Impact | Complexity | Recommendation |
|-------------|--------|------------|----------------|
| Plugin cache | Medium | Low | Always enable |
| Plan files | Medium | Low | Always use in CI/CD |
| `-refresh=false` | High | Low | Use during development |
| Split state files | High | Medium | Do when > 200 resources |
| `-parallelism` tuning | Medium | Low | Increase for large configs, decrease if throttled |
| `-target` | High | Low | Development only, never in production |
| CI/CD caching | Medium | Medium | Always implement |
| Module registry | Low | Medium | Use for frequently reused modules |
| Data source consolidation | Low | Low | Always deduplicate |

### Quick Wins

1. Set `TF_PLUGIN_CACHE_DIR` in your shell profile
2. Use `terraform plan -out=tfplan` in all CI/CD pipelines
3. Split configurations with more than 200 resources
4. Cache `.terraform` directory in CI/CD

### Medium-Term Improvements

1. Implement per-module CI/CD with change detection
2. Set up a provider mirror for air-gapped or slow networks
3. Monitor plan duration and set alerts for regressions
4. Review and optimize the dependency graph

---

## Next Steps

- [Dependency Management](dependency-management.md) for optimizing the dependency graph
- [State Management](../01-terraform-basics/state-management.md) for state splitting strategies
- [Terraform Cloud](../02-terraform-intermediate/terraform-cloud.md) for remote execution performance
