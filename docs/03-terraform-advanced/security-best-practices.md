# Security Best Practices

## Table of Contents

- [Security Overview](#security-overview)
- [State Encryption](#state-encryption)
- [Secrets Management](#secrets-management)
- [IAM Least Privilege](#iam-least-privilege)
- [Provider Authentication](#provider-authentication)
- [Sensitive Variables](#sensitive-variables)
- [OIDC for CI/CD](#oidc-for-cicd)
- [Policy as Code](#policy-as-code)
- [Static Analysis and Scanning](#static-analysis-and-scanning)
- [Supply Chain Security](#supply-chain-security)
- [Network Security](#network-security)
- [Audit and Compliance](#audit-and-compliance)
- [Security Checklist](#security-checklist)

---

## Security Overview

Terraform manages infrastructure that forms the foundation of your security posture. A compromised Terraform configuration or workflow can lead to:

- Exposed secrets (passwords, API keys, certificates)
- Overly permissive IAM roles
- Public-facing resources that should be private
- Unencrypted data at rest or in transit
- Unauthorized infrastructure changes

Security in Terraform spans three areas:

1. **The Terraform workflow**: How credentials are stored, how state is protected, how changes are reviewed
2. **The infrastructure being created**: IAM policies, encryption, network configurations
3. **The supply chain**: Provider and module integrity

---

## State Encryption

The Terraform state file contains sensitive data including resource attributes, passwords, private keys, and connection strings. Protecting it is critical.

### S3 Backend with KMS Encryption

```hcl
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    kms_key_id     = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    dynamodb_table = "terraform-state-lock"
  }
}
```

### KMS Key Configuration

```hcl
resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowKeyManagement"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::123456789012:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowTerraformStateAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::123456789012:role/TerraformCI",
            "arn:aws:iam::123456789012:role/PlatformTeam",
          ]
        }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
        ]
        Resource = "*"
      }
    ]
  })
}
```

### S3 Bucket Security

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "mycompany-terraform-state"
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning for recovery
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enforce encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
    bucket_key_enabled = true
  }
}

# Restrict access with bucket policy
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnencryptedTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*",
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "DenyIncorrectEncryption"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.terraform_state.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      }
    ]
  })
}
```

---

## Secrets Management

### Never Hardcode Secrets

```hcl
# NEVER do this
resource "aws_db_instance" "main" {
  password = "super-secret-password"    # Committed to Git!
}

# NEVER do this either
variable "db_password" {
  default = "super-secret-password"     # Also in Git!
}
```

### Use AWS Secrets Manager

```hcl
# Create a secret
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "prod/database/password"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db.result
}

# Read a secret
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/database/password"
}

resource "aws_db_instance" "main" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

### Use SSM Parameter Store

```hcl
# Store a secret
resource "aws_ssm_parameter" "db_password" {
  name   = "/prod/database/password"
  type   = "SecureString"
  value  = random_password.db.result

  lifecycle {
    ignore_changes = [value]    # Don't overwrite manual rotations
  }
}

# Read a secret
data "aws_ssm_parameter" "db_password" {
  name            = "/prod/database/password"
  with_decryption = true
}
```

### Use HashiCorp Vault

```hcl
provider "vault" {
  address = "https://vault.internal:8200"
}

data "vault_generic_secret" "db" {
  path = "secret/prod/database"
}

resource "aws_db_instance" "main" {
  username = data.vault_generic_secret.db.data["username"]
  password = data.vault_generic_secret.db.data["password"]
}
```

### Generate Random Passwords

```hcl
resource "random_password" "db" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "main" {
  password = random_password.db.result
}

# Store the generated password in Secrets Manager for applications to read
resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = random_password.db.result
}
```

**Note**: Even with Secrets Manager or Vault, the secret value is stored in the Terraform state file. Ensure state encryption and access controls.

---

## IAM Least Privilege

### Terraform Execution Role

Create a dedicated IAM role for Terraform with only the permissions it needs:

```hcl
# Role for Terraform CI/CD
resource "aws_iam_role" "terraform" {
  name = "TerraformCI"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:myorg/infra:ref:refs/heads/main"
        }
      }
    }]
  })
}
```

### Scoped Permissions

Instead of `AdministratorAccess`, create specific policies:

```hcl
data "aws_iam_policy_document" "terraform_permissions" {
  # EC2 management
  statement {
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:CreateVpc",
      "ec2:DeleteVpc",
      "ec2:CreateSubnet",
      "ec2:DeleteSubnet",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:CreateSecurityGroup",
      "ec2:DeleteSecurityGroup",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:CreateTags",
      "ec2:DeleteTags",
    ]
    resources = ["*"]
  }

  # State management
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::mycompany-terraform-state",
      "arn:aws:s3:::mycompany-terraform-state/*",
    ]
  }

  # State locking
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]
    resources = [
      "arn:aws:dynamodb:us-east-1:123456789012:table/terraform-state-lock",
    ]
  }

  # KMS for state encryption
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey",
    ]
    resources = [
      aws_kms_key.terraform_state.arn,
    ]
  }
}
```

### Permission Boundaries

Limit the maximum permissions Terraform can grant to roles it creates:

```hcl
resource "aws_iam_role" "app" {
  name                 = "app-role"
  permissions_boundary = aws_iam_policy.boundary.arn
  assume_role_policy   = data.aws_iam_policy_document.app_assume.json
}

resource "aws_iam_policy" "boundary" {
  name = "terraform-permission-boundary"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
      {
        Effect = "Deny"
        Action = [
          "iam:CreateUser",
          "iam:CreateAccessKey",
          "organizations:*",
          "account:*",
        ]
        Resource = "*"
      }
    ]
  })
}
```

---

## Provider Authentication

### Authentication Priority

Never hardcode credentials. Use this priority order:

1. **IAM Roles** (EC2 instance profiles, ECS task roles, EKS IRSA) -- best for production
2. **OIDC Federation** -- best for CI/CD
3. **Environment variables** -- acceptable for local development
4. **Shared credentials file** (`~/.aws/credentials`) -- acceptable for local development
5. **Static credentials in provider block** -- never use this

### Secure Provider Configuration

```hcl
# Good: no credentials in config, uses ambient credentials
provider "aws" {
  region = "us-east-1"
}

# Acceptable for multi-account: assume role
provider "aws" {
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::987654321098:role/TerraformRole"
  }
}

# Bad: static credentials
provider "aws" {
  access_key = "AKIA..."     # NEVER do this
  secret_key = "..."         # NEVER do this
}
```

---

## Sensitive Variables

### Mark Variables as Sensitive

```hcl
variable "database_password" {
  type      = string
  sensitive = true
}

variable "api_key" {
  type      = string
  sensitive = true
}
```

### Provide Sensitive Values Securely

```bash
# Environment variables (CI/CD)
export TF_VAR_database_password="$DB_PASSWORD"

# Variable file not committed to Git
terraform apply -var-file="secrets.tfvars"

# From a secrets manager in CI/CD
export TF_VAR_database_password=$(aws secretsmanager get-secret-value \
  --secret-id prod/db/password \
  --query SecretString --output text)
```

### Sensitive Outputs

```hcl
output "connection_string" {
  value     = "postgresql://${var.db_user}:${var.db_password}@${aws_db_instance.main.endpoint}/mydb"
  sensitive = true
}
```

### Limitations of the sensitive Flag

The `sensitive` flag only redacts values from CLI output and logs. The actual values are still stored in plain text in the state file. State encryption is essential.

---

## OIDC for CI/CD

OIDC (OpenID Connect) federation allows CI/CD pipelines to authenticate with AWS without long-lived access keys.

### GitHub Actions OIDC

```hcl
# Create the OIDC provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Create the role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "GitHubActionsTerraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:myorg/infra:*"
        }
      }
    }]
  })
}
```

### GitHub Actions Workflow

```yaml
name: Terraform
on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsTerraform
          aws-region: us-east-1

      - uses: hashicorp/setup-terraform@v3

      - run: terraform init
      - run: terraform plan -out=tfplan
      - run: terraform apply tfplan
```

### GitLab CI OIDC

```hcl
resource "aws_iam_openid_connect_provider" "gitlab" {
  url             = "https://gitlab.com"
  client_id_list  = ["https://gitlab.com"]
  thumbprint_list = ["b3dd7606d2b5a8b4a13771dbecc9ee1cecafa38a"]
}

resource "aws_iam_role" "gitlab_ci" {
  name = "GitLabCITerraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.gitlab.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "gitlab.com:sub" = "project_path:myorg/infra:ref_type:branch:ref:main"
        }
      }
    }]
  })
}
```

---

## Policy as Code

### Sentinel (Terraform Cloud/Enterprise)

Sentinel enforces policies before Terraform applies changes:

```python
# Prevent public S3 buckets
import "tfplan/v2" as tfplan

s3_buckets = filter tfplan.resource_changes as _, rc {
    rc.type is "aws_s3_bucket_public_access_block"
}

main = rule {
    all s3_buckets as _, bucket {
        bucket.change.after.block_public_acls is true and
        bucket.change.after.block_public_policy is true
    }
}
```

### Open Policy Agent (OPA)

OPA evaluates Terraform plans against Rego policies:

```rego
# policy/deny_public_s3.rego
package terraform

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not has_public_access_block(resource.address)
    msg := sprintf("S3 bucket %s must have a public access block", [resource.address])
}
```

Run OPA against a plan:

```bash
terraform plan -out=tfplan
terraform show -json tfplan > plan.json
opa eval -i plan.json -d policy/ "data.terraform.deny"
```

### Checkov

Checkov is a static analysis tool that scans Terraform configurations for security misconfigurations:

```bash
# Install
pip install checkov

# Scan a directory
checkov -d .

# Scan with specific checks
checkov -d . --check CKV_AWS_18,CKV_AWS_19

# Output as JSON
checkov -d . -o json

# Skip specific checks
checkov -d . --skip-check CKV_AWS_145
```

Common Checkov checks:

| Check ID | Description |
|----------|-------------|
| CKV_AWS_18 | Ensure S3 bucket has logging enabled |
| CKV_AWS_19 | Ensure S3 bucket has encryption enabled |
| CKV_AWS_20 | Ensure S3 bucket does not allow public READ |
| CKV_AWS_23 | Ensure every security group rule has a description |
| CKV_AWS_24 | Ensure no security group allows ingress from 0.0.0.0/0 to port 22 |
| CKV_AWS_145 | Ensure RDS instance is encrypted at rest |

### tfsec

tfsec is another static analysis tool focused on Terraform security:

```bash
# Install
brew install tfsec

# Scan
tfsec .

# Scan with custom severity threshold
tfsec . --minimum-severity HIGH

# Output as JSON
tfsec . -f json
```

### CI/CD Integration

```yaml
# GitHub Actions
- name: Checkov Scan
  uses: bridgecrewio/checkov-action@v12
  with:
    directory: .
    framework: terraform
    soft_fail: false

- name: tfsec Scan
  uses: aquasecurity/tfsec-action@v1.0.0
  with:
    soft_fail: false
```

---

## Static Analysis and Scanning

### Pre-Commit Hooks

Automate security scanning before every commit:

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.86.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
      - id: terraform_checkov
      - id: terraform_tfsec

  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: detect-private-key
      - id: check-merge-conflict
      - id: no-commit-to-branch
        args: [--branch, main]
```

```bash
# Install pre-commit
pip install pre-commit
pre-commit install
```

### TFLint

TFLint checks for Terraform best practices and cloud provider-specific issues:

```bash
# Install
brew install tflint

# Initialize (downloads rule plugins)
tflint --init

# Run
tflint
```

```hcl
# .tflint.hcl
plugin "aws" {
  enabled = true
  version = "0.28.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}
```

---

## Supply Chain Security

### Verify Provider Integrity

The `.terraform.lock.hcl` file contains cryptographic hashes of provider binaries:

```hcl
provider "registry.terraform.io/hashicorp/aws" {
  version     = "5.31.0"
  constraints = "~> 5.0"
  hashes = [
    "h1:abc123...",
    "zh:def456...",
  ]
}
```

Always commit this file. Terraform verifies that downloaded providers match these hashes.

### Lock File for Multiple Platforms

```bash
terraform providers lock \
  -platform=linux_amd64 \
  -platform=darwin_amd64 \
  -platform=darwin_arm64
```

### Module Source Verification

Pin modules to exact versions or commit SHAs:

```hcl
# Good: pinned to exact version
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.4.0"
}

# Better: pinned to commit SHA (for Git sources)
module "vpc" {
  source = "git::https://github.com/myorg/modules.git//vpc?ref=abc1234def5678"
}

# Bad: unpinned (uses latest)
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
}
```

### Private Provider and Module Registries

For sensitive environments, host your own registry:

```hcl
provider_installation {
  filesystem_mirror {
    path    = "/opt/terraform-providers"
    include = ["registry.terraform.io/*/*"]
  }
  direct {
    exclude = ["registry.terraform.io/*/*"]
  }
}
```

---

## Network Security

### Enforce Encryption in Transit

```hcl
# Require HTTPS for S3
resource "aws_s3_bucket_policy" "enforce_tls" {
  bucket = aws_s3_bucket.data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "EnforceTLS"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource = [
        aws_s3_bucket.data.arn,
        "${aws_s3_bucket.data.arn}/*",
      ]
      Condition = {
        Bool = { "aws:SecureTransport" = "false" }
      }
    }]
  })
}

# Enforce TLS 1.2 minimum for ALB
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
```

### Restrict Network Access

```hcl
# No 0.0.0.0/0 on SSH
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidr_blocks    # Specific CIDRs only
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from admin network"
}
```

---

## Audit and Compliance

### CloudTrail for State Operations

```hcl
resource "aws_cloudtrail" "terraform" {
  name           = "terraform-audit"
  s3_bucket_name = aws_s3_bucket.audit_logs.id

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["${aws_s3_bucket.terraform_state.arn}/"]
    }
  }
}
```

### Enable Access Logging on State Bucket

```hcl
resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "terraform-state-access/"
}
```

### Tag Everything for Governance

```hcl
provider "aws" {
  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Environment = var.environment
      Team        = var.team
      CostCenter  = var.cost_center
      Repository  = "github.com/myorg/infra"
    }
  }
}
```

---

## Security Checklist

### State Security

- [ ] State is stored in an encrypted remote backend
- [ ] State bucket blocks all public access
- [ ] State bucket requires encryption for all objects
- [ ] State bucket has versioning enabled
- [ ] State bucket has access logging enabled
- [ ] DynamoDB table is used for state locking
- [ ] KMS key rotation is enabled
- [ ] Access to state is restricted by IAM policies

### Secrets Management

- [ ] No secrets hardcoded in `.tf` files
- [ ] No secrets in `terraform.tfvars` committed to Git
- [ ] Sensitive variables are marked as `sensitive`
- [ ] Secrets are sourced from Secrets Manager, SSM, or Vault
- [ ] `.gitignore` excludes `.tfvars`, `.tfstate`, and `.terraform`

### Authentication

- [ ] No static access keys in provider configuration
- [ ] CI/CD uses OIDC federation (no long-lived keys)
- [ ] Terraform execution role follows least privilege
- [ ] Permission boundaries prevent privilege escalation
- [ ] MFA is required for human access to Terraform state

### Code Quality

- [ ] Pre-commit hooks run `terraform fmt`, `validate`, `tflint`, `checkov`
- [ ] CI pipeline includes security scanning
- [ ] Provider versions are pinned
- [ ] Module versions are pinned
- [ ] `.terraform.lock.hcl` is committed to Git

### Infrastructure Security

- [ ] All S3 buckets have encryption and public access blocks
- [ ] All RDS instances are encrypted at rest
- [ ] No security groups allow 0.0.0.0/0 on SSH (port 22)
- [ ] All load balancers use TLS 1.2+
- [ ] VPC flow logs are enabled
- [ ] CloudTrail is enabled for all regions

---

## Next Steps

- [State Management](../01-terraform-basics/state-management.md) for state protection details
- [Providers](../01-terraform-basics/providers.md) for provider authentication methods
- [Terraform Cloud](../02-terraform-intermediate/terraform-cloud.md) for managed security features
