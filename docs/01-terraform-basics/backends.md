# Backends

## Table of Contents

- [What are Backends](#what-are-backends)
- [Backend Types](#backend-types)
- [Local Backend](#local-backend)
- [S3 Backend with DynamoDB](#s3-backend-with-dynamodb)
- [GCS Backend](#gcs-backend)
- [Azure Storage Backend](#azure-storage-backend)
- [Consul Backend](#consul-backend)
- [Terraform Cloud Backend](#terraform-cloud-backend)
- [Partial Configuration](#partial-configuration)
- [Migrating Between Backends](#migrating-between-backends)
- [Backend Configuration Best Practices](#backend-configuration-best-practices)
- [Bootstrapping the State Backend](#bootstrapping-the-state-backend)

---

## What are Backends

Backends define where Terraform stores its state file and, in some cases, where operations (plan/apply) are executed. Every Terraform configuration has a backend. If you do not configure one explicitly, Terraform uses the **local** backend, which stores state as a file on disk.

Backends provide two key capabilities:

1. **State Storage**: Where the `terraform.tfstate` file lives (local disk, S3, GCS, Azure Blob, etc.)
2. **State Locking**: Preventing concurrent operations from corrupting state (supported by most remote backends)

Some backends (Terraform Cloud, Terraform Enterprise) also provide **remote operations**, executing `terraform plan` and `terraform apply` on a remote server rather than your local machine.

---

## Backend Types

| Backend | State Storage | Locking | Remote Ops | Best For |
|---------|--------------|---------|------------|----------|
| `local` | Local disk | No | No | Learning, solo development |
| `s3` | AWS S3 | Yes (DynamoDB) | No | AWS-centric teams |
| `gcs` | Google Cloud Storage | Yes (built-in) | No | GCP-centric teams |
| `azurerm` | Azure Blob Storage | Yes (built-in) | No | Azure-centric teams |
| `consul` | Consul KV store | Yes (built-in) | No | HashiCorp ecosystem |
| `cloud` | Terraform Cloud | Yes (built-in) | Yes | Teams using HCP Terraform |
| `http` | Any HTTP endpoint | Optional | No | Custom backends |
| `pg` | PostgreSQL | Yes (built-in) | No | Organizations with existing PG |
| `cos` | Tencent Cloud COS | Yes (built-in) | No | Tencent Cloud users |
| `oss` | Alibaba Cloud OSS | Yes (TableStore) | No | Alibaba Cloud users |

---

## Local Backend

The default backend. State is stored as a file in the working directory.

```hcl
# Explicit configuration (optional — this is the default)
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
```

You can customize the path:

```hcl
terraform {
  backend "local" {
    path = "state/production.tfstate"
  }
}
```

### When to Use Local Backend

- Learning Terraform
- Quick experiments and prototypes
- Single-developer projects with no collaboration needs
- When combined with a script that uploads state elsewhere

### Limitations

- No state locking (concurrent runs can corrupt state)
- No encryption at rest (unless the filesystem is encrypted)
- Not accessible to team members
- State is lost if the disk fails

---

## S3 Backend with DynamoDB

The most popular backend for AWS teams. S3 stores the state file; DynamoDB provides state locking and consistency checking.

### Prerequisites

You need these AWS resources before configuring the backend:

1. An S3 bucket for state storage
2. A DynamoDB table for state locking
3. (Optional) A KMS key for encryption

### Backend Configuration

```hcl
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "prod/networking/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    kms_key_id     = "alias/terraform-state-key"

    # Optional: use a specific profile
    # profile = "terraform"

    # Optional: assume a role
    # role_arn = "arn:aws:iam::123456789012:role/TerraformStateAccess"
  }
}
```

### Creating the S3 Bucket

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "mycompany-terraform-state"

  tags = {
    Name    = "Terraform State"
    Purpose = "terraform-state"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

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

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}
```

### Creating the DynamoDB Table

```hcl
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name    = "Terraform State Lock"
    Purpose = "terraform-state-lock"
  }
}
```

### Creating the KMS Key

```hcl
resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 30
  enable_key_rotation     = true
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/terraform-state-key"
  target_key_id = aws_kms_key.terraform_state.key_id
}
```

### S3 Backend Key Strategy

Organize state files with a clear key hierarchy:

```
s3://mycompany-terraform-state/
  global/
    iam/terraform.tfstate
    dns/terraform.tfstate
  us-east-1/
    prod/
      networking/terraform.tfstate
      compute/terraform.tfstate
      database/terraform.tfstate
    staging/
      networking/terraform.tfstate
      compute/terraform.tfstate
  eu-west-1/
    prod/
      networking/terraform.tfstate
```

---

## GCS Backend

Google Cloud Storage backend with built-in state locking.

```hcl
terraform {
  backend "gcs" {
    bucket  = "mycompany-terraform-state"
    prefix  = "prod/networking"
    project = "my-project-id"
  }
}
```

### Create the GCS Bucket

```hcl
resource "google_storage_bucket" "terraform_state" {
  name     = "mycompany-terraform-state"
  location = "US"
  project  = "my-project-id"

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      num_newer_versions = 30
    }
  }
}
```

GCS provides built-in locking via object generation numbers. No separate lock table is needed.

---

## Azure Storage Backend

Azure Blob Storage backend with built-in state locking via blob leases.

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "mycompanytfstate"
    container_name       = "tfstate"
    key                  = "prod/networking/terraform.tfstate"
  }
}
```

### Create the Azure Storage Account

```hcl
resource "azurerm_resource_group" "terraform_state" {
  name     = "terraform-state-rg"
  location = "East US"
}

resource "azurerm_storage_account" "terraform_state" {
  name                     = "mycompanytfstate"
  resource_group_name      = azurerm_resource_group.terraform_state.name
  location                 = azurerm_resource_group.terraform_state.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  blob_properties {
    versioning_enabled = true
  }
}

resource "azurerm_storage_container" "terraform_state" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.terraform_state.id
  container_access_type = "private"
}
```

---

## Consul Backend

HashiCorp Consul can serve as a backend with built-in locking.

```hcl
terraform {
  backend "consul" {
    address = "consul.example.com:8500"
    scheme  = "https"
    path    = "terraform/prod/networking"

    # Authentication
    access_token = var.consul_token   # NOTE: use env var CONSUL_HTTP_TOKEN instead
  }
}
```

Consul is a good choice if your organization already runs Consul for service discovery and configuration management.

---

## Terraform Cloud Backend

Terraform Cloud (HCP Terraform) provides state storage, locking, remote operations, and collaboration features.

```hcl
terraform {
  cloud {
    organization = "my-organization"

    workspaces {
      name = "prod-networking"
    }
  }
}
```

### Using Workspace Tags

```hcl
terraform {
  cloud {
    organization = "my-organization"

    workspaces {
      tags = ["prod", "networking"]
    }
  }
}
```

### Authentication

```bash
# Login to Terraform Cloud
terraform login

# This stores a token in ~/.terraform.d/credentials.tfrc.json
```

For CI/CD:

```bash
export TF_TOKEN_app_terraform_io="your-team-token"
```

### Benefits of Terraform Cloud

- **Remote execution**: Plans and applies run on Terraform Cloud servers
- **Sentinel policies**: Enforce compliance rules before apply
- **Cost estimation**: See estimated costs before provisioning
- **VCS integration**: Trigger runs automatically on Git push
- **Private registry**: Host and share modules internally
- **RBAC**: Role-based access control for teams

---

## Partial Configuration

You can omit some backend arguments from the configuration and provide them at init time. This is useful for:

- Keeping secrets out of configuration files
- Using the same configuration with different backends per environment
- CI/CD pipelines where backend details come from environment variables

### Configuration File with Partial Backend

```hcl
terraform {
  backend "s3" {
    # bucket, key, region provided at init time
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### Providing Values at Init Time

**Method 1: Command-line flags**

```bash
terraform init \
  -backend-config="bucket=mycompany-terraform-state" \
  -backend-config="key=prod/networking/terraform.tfstate" \
  -backend-config="region=us-east-1"
```

**Method 2: Backend configuration file**

Create `backend.hcl`:

```hcl
bucket = "mycompany-terraform-state"
key    = "prod/networking/terraform.tfstate"
region = "us-east-1"
```

```bash
terraform init -backend-config=backend.hcl
```

**Method 3: Environment variables** (for some backends)

The S3 backend supports `AWS_DEFAULT_REGION`, `AWS_ACCESS_KEY_ID`, etc.

### Per-Environment Backend Files

```
configs/
  backend-dev.hcl
  backend-staging.hcl
  backend-prod.hcl
```

```bash
# Initialize for development
terraform init -backend-config=configs/backend-dev.hcl

# Initialize for production
terraform init -backend-config=configs/backend-prod.hcl
```

---

## Migrating Between Backends

### Local to S3

1. Add the S3 backend configuration to your `terraform` block.
2. Run `terraform init -migrate-state`.
3. Terraform asks if you want to copy existing state to the new backend. Answer `yes`.
4. Verify with `terraform state list`.
5. Delete the local `terraform.tfstate` file.

```bash
# After adding backend "s3" { ... } to your config:
terraform init -migrate-state

# Terraform prompts:
# Do you want to copy existing state to the new backend? yes

# Verify
terraform state list
```

### S3 to Terraform Cloud

1. Replace the `backend "s3"` block with a `cloud` block.
2. Run `terraform init -migrate-state`.
3. Terraform migrates the state to Terraform Cloud.

### Reconfiguring a Backend

If you need to change backend settings (different bucket, different key):

```bash
# Option 1: Migrate state to new location
terraform init -migrate-state

# Option 2: Reinitialize from scratch (does NOT migrate state)
terraform init -reconfigure
```

**Warning**: `-reconfigure` does not copy state. If you use it, you start with an empty state in the new backend. Use `-migrate-state` to preserve state.

### Emergency: Backend Unavailable

If your remote backend is temporarily unavailable:

```bash
# Pull the last known state to a local file
# (if you have a backup or the backend comes back)
terraform state pull > emergency_backup.json

# Temporarily switch to local backend
# Change backend to "local" and run:
terraform init -reconfigure

# Push the state
terraform state push emergency_backup.json

# Work locally until the remote backend is restored
# Then switch back and migrate
```

---

## Backend Configuration Best Practices

### 1. Use Remote State from the Start

Migrating from local to remote state later is possible but adds risk and effort. Start with a remote backend even for small projects.

### 2. Enable Encryption

Always encrypt state at rest. State files contain secrets.

```hcl
backend "s3" {
  encrypt    = true
  kms_key_id = "alias/terraform-state-key"
}
```

### 3. Enable Versioning

State versioning lets you recover from corruption or accidental overwrites:

```hcl
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}
```

### 4. Restrict Access

Only CI/CD pipelines and authorized personnel should access the state bucket:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::terraform-state",
        "arn:aws:s3:::terraform-state/*"
      ],
      "Condition": {
        "StringNotEquals": {
          "aws:PrincipalArn": [
            "arn:aws:iam::123456789012:role/TerraformCI",
            "arn:aws:iam::123456789012:role/PlatformTeam"
          ]
        }
      }
    }
  ]
}
```

### 5. Separate State per Component

Do not put your entire infrastructure in one state file. Break it into logical components:

```
# Each has its own state file
infrastructure/network/
infrastructure/compute/
infrastructure/database/
infrastructure/monitoring/
```

Benefits:

- Faster plan and apply (fewer resources to process)
- Reduced blast radius (a mistake in compute does not affect networking)
- Independent deployments per team

### 6. Use Consistent Naming Conventions

State keys should follow a predictable pattern:

```
{environment}/{region}/{component}/terraform.tfstate
```

Example: `prod/us-east-1/networking/terraform.tfstate`

### 7. Use Partial Configuration for Secrets

Never hardcode credentials in backend configuration. Use partial configuration and provide secrets via environment variables or backend config files.

### 8. Monitor State Operations

Enable CloudTrail logging on the S3 bucket to track who accessed or modified state files:

```hcl
resource "aws_s3_bucket_logging" "state" {
  bucket = aws_s3_bucket.state.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "state-access-logs/"
}
```

---

## Bootstrapping the State Backend

A chicken-and-egg problem: you need to create the S3 bucket and DynamoDB table before you can use them as a backend. Here is the recommended approach.

### Step 1: Create a Bootstrap Project

```hcl
# bootstrap/main.tf
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Start with local state for bootstrapping
  backend "local" {
    path = "bootstrap.tfstate"
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "mycompany-terraform-state"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
```

### Step 2: Apply the Bootstrap

```bash
cd bootstrap
terraform init
terraform apply
```

### Step 3: Migrate Bootstrap State to S3 (Optional)

After the bucket and table exist, you can migrate the bootstrap project's own state to S3:

```hcl
# Change the backend block in bootstrap/main.tf to:
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "bootstrap/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

```bash
terraform init -migrate-state
# Answer yes to copy state
```

### Step 4: Use the Backend in All Other Projects

```hcl
# Any other project:
terraform {
  backend "s3" {
    bucket         = "mycompany-terraform-state"
    key            = "prod/networking/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

---

## Next Steps

- [State Management](state-management.md) for state commands and operations
- [Workspaces](../02-terraform-intermediate/workspaces.md) for environment isolation with state
- [Terraform Cloud](../02-terraform-intermediate/terraform-cloud.md) for a managed backend solution
