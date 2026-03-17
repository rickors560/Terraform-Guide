# Global Environment

Account-wide resources shared across all environments.

## Resources Created

- **IAM Roles**: Admin (MFA-required), Developer (MFA-required, restricted), Readonly
- **Route53**: Primary hosted zone for the domain
- **Account Settings**: S3 public access block, EBS default encryption, password policy

## Usage

```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars

# Initialize and apply
terraform init
terraform plan
terraform apply
```

## Prerequisites

- S3 bucket `myapp-terraform-state` and DynamoDB table `myapp-terraform-locks` must exist
- AWS credentials with admin access for initial setup

## Outputs

After apply, note the Route53 name servers -- update your domain registrar NS records accordingly.
