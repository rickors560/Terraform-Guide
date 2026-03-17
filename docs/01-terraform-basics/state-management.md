# State Management

## Table of Contents

- [What is Terraform State](#what-is-terraform-state)
- [Why State Exists](#why-state-exists)
- [State File Structure](#state-file-structure)
- [Local State](#local-state)
- [Remote State](#remote-state)
- [State Locking](#state-locking)
- [State Commands](#state-commands)
- [Sensitive Data in State](#sensitive-data-in-state)
- [State File Best Practices](#state-file-best-practices)
- [State Troubleshooting](#state-troubleshooting)

---

## What is Terraform State

Terraform state is a JSON file that stores the mapping between your Terraform configuration and the real-world infrastructure it manages. Every time you run `terraform apply`, Terraform updates this state file to reflect what it created, modified, or destroyed.

The state file is Terraform's source of truth. Without it, Terraform has no way to know which cloud resources it is responsible for, what their current configuration is, or what needs to change on the next apply.

Default state file: `terraform.tfstate` in the working directory.

---

## Why State Exists

Terraform needs state for four critical reasons:

### 1. Mapping Configuration to Real Resources

Your configuration says `resource "aws_instance" "web" { ... }`. The state records that this resource corresponds to the actual EC2 instance `i-0abc123def456789`. Without this mapping, Terraform would create a new instance every time you run apply.

### 2. Tracking Metadata

State stores metadata including resource dependencies. This enables Terraform to determine the correct order for creating and destroying resources, even when implicit dependencies cannot be inferred from the configuration alone.

### 3. Performance

For large infrastructures, querying every resource from the cloud API on every plan would be slow. State caches attribute values so Terraform can determine changes quickly. You can optionally skip the refresh entirely with `-refresh=false` for faster plans.

### 4. Dependency Resolution

The state stores the dependency graph used during the last apply. When destroying resources, Terraform uses this graph to determine the correct destruction order (reverse of creation order).

---

## State File Structure

A simplified view of `terraform.tfstate`:

```json
{
  "version": 4,
  "terraform_version": "1.7.3",
  "serial": 15,
  "lineage": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "outputs": {
    "instance_ip": {
      "value": "54.123.45.67",
      "type": "string"
    }
  },
  "resources": [
    {
      "mode": "managed",
      "type": "aws_instance",
      "name": "web",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 1,
          "attributes": {
            "id": "i-0abc123def456789",
            "ami": "ami-0abcdef1234567890",
            "instance_type": "t3.micro",
            "public_ip": "54.123.45.67",
            "private_ip": "10.0.1.42",
            "subnet_id": "subnet-0abc123",
            "tags": {
              "Name": "web-server"
            }
          }
        }
      ]
    },
    {
      "mode": "data",
      "type": "aws_ami",
      "name": "ubuntu",
      "provider": "provider[\"registry.terraform.io/hashicorp/aws\"]",
      "instances": [
        {
          "schema_version": 0,
          "attributes": {
            "id": "ami-0abcdef1234567890",
            "name": "ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-20240101"
          }
        }
      ]
    }
  ]
}
```

### Key Fields

| Field | Description |
|-------|-------------|
| `version` | State file format version (currently 4) |
| `terraform_version` | Terraform version that last wrote this state |
| `serial` | Incrementing counter for state changes (used for conflict detection) |
| `lineage` | Unique ID for this state's history (prevents accidental state overwrites) |
| `outputs` | Output values from the configuration |
| `resources` | Array of all managed resources and data sources |

### Resource Entry Fields

| Field | Description |
|-------|-------------|
| `mode` | `managed` (resources) or `data` (data sources) |
| `type` | Resource type (e.g., `aws_instance`) |
| `name` | Local name in the configuration |
| `provider` | Full provider address |
| `instances` | Array of resource instances (one per `count` or `for_each` entry) |
| `attributes` | The actual attribute values of the resource |

---

## Local State

By default, Terraform stores state in a file called `terraform.tfstate` in the root of the working directory.

```
project/
  main.tf
  terraform.tfstate          # Current state
  terraform.tfstate.backup   # Previous state (automatic backup)
```

### When Local State is Acceptable

- Learning and experimentation
- Solo developer projects
- Short-lived infrastructure (created and destroyed in one session)

### Problems with Local State

- **No collaboration**: Only one person has the state file.
- **No locking**: Two people can run apply simultaneously and corrupt state.
- **Risk of loss**: Delete the file and Terraform loses track of all resources.
- **Secrets exposure**: State often contains passwords, tokens, and keys in plain text on disk.

---

## Remote State

Remote state stores the state file in a shared, durable location accessible by the entire team.

### Benefits of Remote State

- **Shared access**: Everyone on the team reads from and writes to the same state.
- **State locking**: Prevents concurrent modifications.
- **Encryption**: Most backends encrypt state at rest.
- **Versioning**: Backends like S3 support versioning for state file recovery.
- **Durability**: Cloud storage is far more durable than a local file.

### Configuring Remote State with S3

```hcl
terraform {
  backend "s3" {
    bucket         = "my-company-terraform-state"
    key            = "prod/network/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    kms_key_id     = "alias/terraform-state"
  }
}
```

### Accessing Remote State from Other Configurations

Use the `terraform_remote_state` data source to read outputs from another state:

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "my-company-terraform-state"
    key    = "prod/network/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "web" {
  subnet_id = data.terraform_remote_state.network.outputs.private_subnet_id
}
```

**Alternative**: Use `terraform_remote_state` sparingly. Prefer passing values through variables or using data sources to look up resources directly. `terraform_remote_state` creates tight coupling between configurations.

---

## State Locking

State locking prevents concurrent state operations that could corrupt the state file. When a Terraform operation begins, it acquires a lock. When it finishes, it releases the lock. If another operation tries to run while the lock is held, it waits or fails.

### How Locking Works with S3 + DynamoDB

```
User A: terraform apply
  1. Acquire lock (write to DynamoDB)
  2. Read state from S3
  3. Make changes
  4. Write state to S3
  5. Release lock (delete from DynamoDB)

User B: terraform apply (concurrent)
  1. Attempt to acquire lock -> BLOCKED
  2. Error: "state locked by User A"
```

### DynamoDB Lock Table

Create the lock table:

```hcl
resource "aws_dynamodb_table" "terraform_lock" {
  name         = "terraform-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "Terraform State Lock"
    Purpose = "terraform"
  }
}
```

The lock entry contains:

```json
{
  "LockID": "my-company-terraform-state/prod/network/terraform.tfstate",
  "Info": {
    "ID": "a1b2c3d4-e5f6-7890",
    "Operation": "OperationTypeApply",
    "Who": "user@hostname",
    "Version": "1.7.3",
    "Created": "2024-01-15T10:30:00Z",
    "Path": "prod/network/terraform.tfstate"
  }
}
```

### Force Unlocking

If Terraform crashes or is killed during an operation, the lock may remain. After verifying no other operation is running:

```bash
# The error message provides the lock ID
terraform force-unlock a1b2c3d4-e5f6-7890
```

### Disabling Locking

You can disable locking (not recommended):

```bash
terraform apply -lock=false
```

Set a lock timeout to wait instead of immediately failing:

```bash
terraform apply -lock-timeout=5m
```

---

## State Commands

### terraform state list

List all resources in the state:

```bash
terraform state list
# aws_instance.web
# aws_s3_bucket.data
# aws_security_group.web
# module.vpc.aws_vpc.main
# module.vpc.aws_subnet.private[0]
# module.vpc.aws_subnet.private[1]

# Filter by address prefix
terraform state list module.vpc
terraform state list aws_instance
```

### terraform state show

Show detailed attributes for a specific resource:

```bash
terraform state show aws_instance.web

# For indexed resources
terraform state show 'aws_instance.web[0]'
terraform state show 'aws_instance.web["app"]'
```

### terraform state mv

Move or rename resources in the state:

```bash
# Rename a resource (avoids destroy/recreate)
terraform state mv aws_instance.web aws_instance.application

# Move into a module
terraform state mv aws_instance.web module.compute.aws_instance.web

# Move between state files
terraform state mv -state=old.tfstate -state-out=new.tfstate \
  aws_instance.web aws_instance.web
```

After `state mv`, update your configuration to match the new address. On the next plan, Terraform should show no changes.

### terraform state rm

Remove a resource from state without destroying the infrastructure:

```bash
# Stop managing a resource (it continues to exist in AWS)
terraform state rm aws_instance.web

# Remove an entire module
terraform state rm module.vpc

# Dry run
terraform state rm -dry-run aws_instance.web
```

Use cases:

- Transferring resource management to another Terraform configuration
- Removing resources that were created outside Terraform and accidentally imported
- Splitting a monolithic state into multiple smaller states

### terraform state pull

Download and display the current remote state:

```bash
# Print state to stdout
terraform state pull

# Save to a file (for backup or inspection)
terraform state pull > state_backup.json

# Pipe to jq for analysis
terraform state pull | jq '.resources | length'
terraform state pull | jq '.resources[].type' | sort | uniq -c | sort -rn
```

### terraform state push

Upload a local state file to the remote backend:

```bash
terraform state push state_backup.json

# Force push (overrides lineage and serial checks)
terraform state push -force state_backup.json
```

**Warning**: `state push` is dangerous. It can overwrite your remote state. Only use it when recovering from state corruption or migrating states. Always back up the remote state first with `state pull`.

### terraform state replace-provider

Change the provider for resources in the state:

```bash
# Migrate from hashicorp/aws to a custom registry
terraform state replace-provider hashicorp/aws custom-registry/aws
```

---

## Sensitive Data in State

**The Terraform state file often contains secrets in plain text.** Even if you mark variables as `sensitive`, the actual values are stored in state. Common secrets found in state:

- Database passwords (`aws_db_instance` password attribute)
- Access keys and secret keys
- TLS private keys
- API tokens
- Initial admin passwords

### Protecting State

1. **Encrypt at rest**: Use S3 server-side encryption or KMS.

```hcl
terraform {
  backend "s3" {
    bucket     = "terraform-state"
    key        = "terraform.tfstate"
    region     = "us-east-1"
    encrypt    = true           # SSE-S3 encryption
    kms_key_id = "alias/terraform"  # SSE-KMS for stronger encryption
  }
}
```

2. **Encrypt in transit**: All remote backends use TLS. Ensure you are using HTTPS.

3. **Restrict access**: Use IAM policies to limit who can read the state bucket.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::terraform-state/*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalTag/Team": "platform"
        }
      }
    }
  ]
}
```

4. **Enable versioning**: Recover from accidental state corruption.

```hcl
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

5. **Use external secrets managers**: Instead of storing secrets in Terraform, reference them from Vault, AWS Secrets Manager, or SSM Parameter Store:

```hcl
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "prod/database/password"
}

resource "aws_db_instance" "main" {
  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}
```

The password still appears in state, but it is a reference that can be rotated independently.

---

## State File Best Practices

### 1. Never Edit State Manually

Always use `terraform state` commands or `terraform import`. Manually editing JSON risks corruption.

### 2. Never Commit State to Version Control

Add to `.gitignore`:

```gitignore
*.tfstate
*.tfstate.*
```

State files contain secrets. They belong in an encrypted remote backend, not in Git.

### 3. Use Remote State from Day One

Even for small projects, configure a remote backend immediately. Migrating later adds complexity.

### 4. One State per Environment

Separate state files for dev, staging, and production:

```
terraform-state-bucket/
  dev/terraform.tfstate
  staging/terraform.tfstate
  prod/terraform.tfstate
```

This ensures a bad apply in dev cannot affect production state.

### 5. Keep State Files Small

Large state files (thousands of resources) slow down every operation. Split into logical units:

```
infrastructure/
  network/          # VPCs, subnets, route tables
  compute/          # EC2, ASGs, ALBs
  database/         # RDS, ElastiCache
  monitoring/       # CloudWatch, SNS
```

Each directory has its own state file. Use `terraform_remote_state` or data sources to share information between them.

### 6. Enable Versioning on the State Bucket

If state is corrupted, versioning lets you restore a previous version:

```bash
# List state file versions in S3
aws s3api list-object-versions \
  --bucket terraform-state \
  --prefix prod/terraform.tfstate

# Download a specific version
aws s3api get-object \
  --bucket terraform-state \
  --key prod/terraform.tfstate \
  --version-id "abc123" \
  restored-state.json
```

### 7. Back Up Before Risky Operations

Before state surgery (mv, rm, import), always back up:

```bash
terraform state pull > backup_$(date +%Y%m%d_%H%M%S).json
```

### 8. Use Lifecycle Rules for State Bucket

Keep old state versions but expire them after a retention period:

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "state" {
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

---

## State Troubleshooting

### "State is locked"

Someone (or a crashed process) holds the lock:

```bash
# Check who holds the lock (the error message shows this)
# If you confirm no operation is running:
terraform force-unlock LOCK_ID
```

### "State lineage mismatch"

You are trying to use a state file with a different lineage (history). This happens when you accidentally mix state files from different projects:

```bash
# If you are certain this is correct, use force push
terraform state push -force correct_state.json
```

### "Resource already exists"

The resource exists in the cloud but not in state. Import it:

```bash
terraform import aws_instance.web i-0abc123def456
```

### "Drift detected"

The real infrastructure differs from the state. Run refresh:

```bash
terraform apply -refresh-only
```

This updates the state to match reality without changing infrastructure.

### State corruption recovery

1. Download the latest state: `terraform state pull > current.json`
2. Check S3 versioning for a known-good previous version
3. Restore: `terraform state push previous_good_state.json`
4. Run `terraform plan` to verify

---

## Next Steps

- [Backends](backends.md) for detailed backend configuration
- [Security Best Practices](../03-terraform-advanced/security-best-practices.md) for state encryption
- [Import Existing Infrastructure](../03-terraform-advanced/import-existing.md) for managing existing resources
