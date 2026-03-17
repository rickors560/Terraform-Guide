# Bootstrap — Terraform Remote Backend

This directory contains the Terraform configuration that creates the S3 bucket and DynamoDB table used as the remote backend for all other Terraform configurations in this repository.

## Resources Created

| Resource | Purpose |
|---|---|
| **S3 Bucket** (`{project}-{env}-terraform-state`) | Stores Terraform state files with versioning, encryption, and lifecycle policies |
| **DynamoDB Table** (`{project}-{env}-terraform-locks`) | Provides state locking to prevent concurrent modifications |

## S3 Bucket Features

- **Versioning:** Enabled — allows state recovery from any previous version
- **Encryption:** AWS KMS server-side encryption with bucket key enabled
- **Public access:** All public access blocked
- **Lifecycle:** Non-current versions transition to STANDARD_IA after 30 days and expire after 90 days
- **Bucket policy:** Enforces TLS-only access and encrypted uploads
- **Access logging:** Self-logging to the `access-logs/` prefix

## DynamoDB Table Features

- **Billing:** PAY_PER_REQUEST (on-demand) — no capacity planning needed
- **Encryption:** Server-side encryption enabled
- **Point-in-time recovery:** Enabled for table backup

## Prerequisites

- AWS CLI configured with credentials that have permissions to create S3 buckets and DynamoDB tables
- Terraform >= 1.9.0 installed

## Usage

```bash
cd bootstrap/

# Initialize (uses local state for the bootstrap itself)
terraform init

# Review the plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan
```

## Outputs

After applying, note the outputs for use in other configurations:

```bash
terraform output
```

Use these values in your environment and component backend blocks:

```hcl
terraform {
  backend "s3" {
    bucket         = "myapp-dev-terraform-state"    # From output: state_bucket_name
    key            = "dev/vpc/terraform.tfstate"     # Unique per component
    region         = "ap-south-1"
    dynamodb_table = "myapp-dev-terraform-locks"     # From output: lock_table_name
    encrypt        = true
  }
}
```

## Important Notes

1. **This configuration uses local state.** The bootstrap is the one Terraform configuration that cannot use a remote backend (because it creates the backend). Keep the `terraform.tfstate` file in this directory safe, or commit it to version control for this directory only.

2. **Do not destroy this without migrating state first.** If you destroy the S3 bucket and DynamoDB table, all other Terraform configurations will lose access to their state files.

3. **State bucket has `force_destroy = false` by default.** To destroy the bucket for cleanup, set `state_bucket_force_destroy = true` in your variables.

## Variables

| Name | Description | Default |
|---|---|---|
| `project_name` | Project name prefix for resource names | `myapp` |
| `environment` | Environment name (dev, staging, prod) | `dev` |
| `region` | AWS region | `ap-south-1` |
| `tags` | Additional tags (Team, CostCenter, Repository) | See `variables.tf` |
| `state_bucket_force_destroy` | Allow bucket destruction with objects | `false` |
