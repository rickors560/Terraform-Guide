# Scripts

Utility and automation scripts for managing the Terraform infrastructure, EKS clusters, secrets, and development environment.

## Scripts

| Script | Purpose |
|---|---|
| `setup.sh` | Check for and install required development tools |
| `bootstrap-backend.sh` | Create the S3 bucket and DynamoDB table for Terraform state |
| `eks-kubeconfig.sh` | Configure kubectl for an EKS cluster |
| `cleanup.sh` | Remove Terraform artifacts (.terraform, plan files, crash logs) |
| `cost-estimate.sh` | Generate Infracost cost estimates for an environment |
| `rotate-secrets.sh` | Rotate secrets in AWS Secrets Manager |
| `generate-docs.sh` | Auto-generate Terraform module documentation with terraform-docs |

## Prerequisites

All scripts require Bash and use `set -euo pipefail` for strict error handling. Individual prerequisites:

- **AWS CLI v2** -- Required by `bootstrap-backend.sh`, `eks-kubeconfig.sh`, `rotate-secrets.sh`, `cost-estimate.sh`
- **Terraform** -- Required by `setup.sh` (installed if missing)
- **kubectl** -- Required by `eks-kubeconfig.sh`, `rotate-secrets.sh` (with `--restart`)
- **Infracost CLI** -- Required by `cost-estimate.sh`, plus `INFRACOST_API_KEY` env var
- **terraform-docs** -- Required by `generate-docs.sh`
- **Python 3** -- Used by `rotate-secrets.sh` for JSON secret rotation

---

### setup.sh

Checks for and installs the required development toolchain: Terraform, AWS CLI, kubectl, Helm, TFLint, terraform-docs, pre-commit, Checkov, and Docker. Creates a `.pre-commit-config.yaml` if one does not exist and installs git hooks.

**Usage:**

```bash
./scripts/setup.sh                # Check and install all tools
./scripts/setup.sh --skip-install # Only verify tools, do not install
./scripts/setup.sh --help
```

**What it does:**
1. Detects OS and architecture (Linux/macOS, amd64/arm64)
2. For each tool: checks if installed, displays version, or attempts installation
3. Creates `.pre-commit-config.yaml` with Terraform formatting, validation, linting, and security hooks
4. Runs `pre-commit install` to activate git hooks
5. Reports a summary of any tools that could not be installed

---

### bootstrap-backend.sh

Creates the S3 bucket and DynamoDB table required by Terraform's S3 backend before the first `terraform init`. Idempotent -- safe to run multiple times. The S3 bucket is configured with versioning, KMS encryption, public access block, and lifecycle rules. The DynamoDB table is configured with PAY_PER_REQUEST billing and point-in-time recovery.

**Usage:**

```bash
./scripts/bootstrap-backend.sh
./scripts/bootstrap-backend.sh --bucket my-tf-state --table my-lock-table --region eu-west-1
./scripts/bootstrap-backend.sh --profile production --dry-run
./scripts/bootstrap-backend.sh --help
```

**Options:**

| Flag | Default | Description |
|---|---|---|
| `--bucket NAME` | `myapp-terraform-state` | S3 bucket name |
| `--table NAME` | `terraform-state-lock` | DynamoDB table name |
| `--region REGION` | `us-east-1` | AWS region |
| `--profile PROFILE` | (none) | AWS CLI profile |
| `--dry-run` | off | Show what would be created |

**What it does:**
1. Verifies AWS credentials via `sts get-caller-identity`
2. Creates S3 bucket (or confirms it exists), enables versioning, KMS encryption, public access block, and multipart upload cleanup
3. Creates DynamoDB table (or confirms it exists) with `LockID` hash key, enables PITR
4. Prints a backend configuration block to paste into your Terraform files

---

### eks-kubeconfig.sh

Configures the local kubeconfig to connect to a specified EKS cluster, verifies connectivity, and displays cluster information (nodes, namespaces, context).

**Usage:**

```bash
./scripts/eks-kubeconfig.sh --cluster myapp-cluster
./scripts/eks-kubeconfig.sh --cluster myapp-cluster --region eu-west-1 --profile staging
./scripts/eks-kubeconfig.sh --cluster myapp-cluster --alias myapp-dev --namespace myapp
./scripts/eks-kubeconfig.sh --cluster myapp-cluster --role-arn arn:aws:iam::123456:role/EKSAdmin
./scripts/eks-kubeconfig.sh --cluster myapp-cluster --dry-run
```

**Options:**

| Flag | Default | Description |
|---|---|---|
| `--cluster NAME` | (required) | EKS cluster name |
| `--region REGION` | `us-east-1` | AWS region |
| `--profile PROFILE` | (none) | AWS CLI profile |
| `--alias ALIAS` | (none) | Context alias in kubeconfig |
| `--role-arn ARN` | (none) | IAM role to assume |
| `--namespace NS` | (none) | Default namespace for the context |
| `--dry-run` | off | Show commands without executing |

**What it does:**
1. Verifies AWS credentials
2. Verifies the EKS cluster exists and is ACTIVE
3. Runs `aws eks update-kubeconfig` with optional alias and role
4. Sets default namespace if specified
5. Tests cluster connectivity and displays node/namespace information

---

### cleanup.sh

Removes Terraform-generated artifacts from the repository: `.terraform/` directories, `.terraform.lock.hcl` files, plan output files, crash logs, backup/override files, and optionally cost reports and SARIF files.

**Usage:**

```bash
./scripts/cleanup.sh              # Remove all artifacts
./scripts/cleanup.sh --dry-run    # Preview what would be deleted
./scripts/cleanup.sh --keep-locks # Keep .terraform.lock.hcl files
./scripts/cleanup.sh --all        # Also remove cost reports and SARIF files
```

**Options:**

| Flag | Description |
|---|---|
| `--dry-run` | Show what would be deleted without deleting |
| `--keep-locks` | Preserve `.terraform.lock.hcl` files (they are committed) |
| `--all` | Also clean cost reports, SARIF files, and drift reports |

---

### cost-estimate.sh

Runs Infracost cost estimation for a specific Terraform environment. Supports table, JSON, and HTML output formats, and can compare against a previous baseline for cost diffs.

**Usage:**

```bash
./scripts/cost-estimate.sh --env dev
./scripts/cost-estimate.sh --env prod --format html
./scripts/cost-estimate.sh --env prod --format json --output costs.json
./scripts/cost-estimate.sh --env staging --compare baseline.json
./scripts/cost-estimate.sh --env prod --sync-usage infracost-usage.yml
```

**Options:**

| Flag | Default | Description |
|---|---|---|
| `--env ENV` | (required) | Environment: `dev`, `staging`, or `prod` |
| `--format FORMAT` | `table` | Output format: `table`, `json`, `html` |
| `--output FILE` | auto-generated | Output file path |
| `--compare FILE` | (none) | Previous JSON baseline for diff |
| `--sync-usage FILE` | (none) | Usage file for usage-based estimates |

---

### rotate-secrets.sh

Rotates secrets in AWS Secrets Manager for a given environment. Generates new random values while preserving JSON key structure. Optionally restarts EKS deployments to pick up the new values.

**Usage:**

```bash
./scripts/rotate-secrets.sh --env dev
./scripts/rotate-secrets.sh --env prod --secret myapp/prod/db-password --restart
./scripts/rotate-secrets.sh --env staging --length 48 --dry-run
./scripts/rotate-secrets.sh --env prod --prefix myapp/prod/ --cluster myapp-cluster --restart
```

**Options:**

| Flag | Default | Description |
|---|---|---|
| `--env ENV` | (required) | Target environment |
| `--secret NAME` | (all matching prefix) | Specific secret name (repeatable) |
| `--prefix PREFIX` | `myapp/<env>/` | Secret name prefix filter |
| `--length N` | 32 | Generated password length |
| `--restart` | off | Restart EKS deployments after rotation |
| `--cluster NAME` | `myapp-cluster` | EKS cluster name (with `--restart`) |
| `--namespace NS` | `myapp` | Kubernetes namespace (with `--restart`) |
| `--region REGION` | `us-east-1` | AWS region |
| `--profile PROFILE` | (none) | AWS CLI profile |
| `--dry-run` | off | Show what would be rotated |

---

### generate-docs.sh

Scans Terraform modules under `modules/`, `components/`, and `environments/` directories, runs `terraform-docs` to generate input/output tables, and inserts the content between `<!-- BEGIN_TF_DOCS -->` / `<!-- END_TF_DOCS -->` markers in each module's README.md.

**Usage:**

```bash
./scripts/generate-docs.sh                              # Generate docs for all modules
./scripts/generate-docs.sh --module modules/vpc         # Single module
./scripts/generate-docs.sh --config .terraform-docs.yml # Custom config
./scripts/generate-docs.sh --check                      # CI mode: fail if any README is outdated
```

**Options:**

| Flag | Description |
|---|---|
| `--module PATH` | Generate docs for a single module directory |
| `--config FILE` | Path to terraform-docs config file |
| `--check` | Exit non-zero if any README would change (for CI) |

## Common Workflows

```bash
# Initial setup for a new developer
./scripts/setup.sh
./scripts/bootstrap-backend.sh --dry-run
./scripts/bootstrap-backend.sh

# Connect to a cluster and deploy
./scripts/eks-kubeconfig.sh --cluster myapp-cluster --namespace myapp
kubectl apply -k k8s/overlays/dev

# Estimate costs before a PR
./scripts/cost-estimate.sh --env prod --format table

# Rotate secrets and restart services
./scripts/rotate-secrets.sh --env staging --restart

# Clean up before switching branches
./scripts/cleanup.sh --keep-locks

# Update module documentation
./scripts/generate-docs.sh
```
