# Importing Existing Infrastructure

## Table of Contents

- [Why Import](#why-import)
- [The terraform import Command](#the-terraform-import-command)
- [Import Blocks (Terraform 1.5+)](#import-blocks-terraform-15)
- [Generating Configuration](#generating-configuration)
- [Step-by-Step Import Workflow](#step-by-step-import-workflow)
- [Bulk Import Strategies](#bulk-import-strategies)
- [Common Resource Import Examples](#common-resource-import-examples)
- [Common Pitfalls](#common-pitfalls)
- [Post-Import Verification](#post-import-verification)
- [Best Practices](#best-practices)

---

## Why Import

Organizations frequently have infrastructure that was created manually through the AWS Console, CLI, or other tools before adopting Terraform. Importing brings these existing resources under Terraform management without recreating them.

Common scenarios:

- **Adopting Terraform**: Migrating manually created infrastructure to IaC
- **Disaster recovery**: Rebuilding state after state file loss
- **Merging projects**: Combining resources from separate management workflows
- **Shadow IT**: Bringing unmanaged resources under governance
- **Provider migration**: Moving resources between Terraform configurations

---

## The terraform import Command

The CLI import command associates an existing resource with a Terraform resource address.

### Syntax

```bash
terraform import <resource_address> <resource_id>
```

### Prerequisites

Before importing, you must:

1. Write a resource block in your configuration that matches the resource to import
2. Run `terraform init` to initialize providers
3. Know the resource's ID (varies by resource type)

### Basic Example

```hcl
# main.tf — write the resource block first
resource "aws_s3_bucket" "imported" {
  bucket = "my-existing-bucket"
}
```

```bash
# Import the existing bucket into state
terraform import aws_s3_bucket.imported my-existing-bucket
```

### Import with count

```bash
terraform import 'aws_instance.web[0]' i-0abc123def456
terraform import 'aws_instance.web[1]' i-0def456ghi789
```

### Import with for_each

```bash
terraform import 'aws_instance.web["app"]' i-0abc123def456
terraform import 'aws_instance.web["api"]' i-0def456ghi789
```

### Import into a Module

```bash
terraform import 'module.vpc.aws_vpc.main' vpc-0abc123def456
terraform import 'module.vpc.aws_subnet.private[0]' subnet-0abc123
```

### Import with a Specific Provider

```bash
terraform import -provider=aws.us_west aws_instance.web i-0abc123def456
```

---

## Import Blocks (Terraform 1.5+)

Terraform 1.5 introduced declarative import blocks. Instead of running `terraform import` commands, you define imports in your configuration files.

### Syntax

```hcl
import {
  to = aws_s3_bucket.imported
  id = "my-existing-bucket"
}
```

### Advantages Over CLI Import

| Feature | CLI `terraform import` | Import blocks |
|---------|----------------------|---------------|
| Declarative | No (imperative command) | Yes (in config) |
| Code review | Cannot be reviewed | Shows in PRs |
| Repeatable | Must remember the command | Part of the codebase |
| Config generation | No | Yes (`-generate-config-out`) |
| Batch import | One at a time | Multiple in one plan |
| Plan preview | No (imports immediately) | Shows in plan output |

### Multiple Import Blocks

```hcl
import {
  to = aws_vpc.main
  id = "vpc-0abc123def456"
}

import {
  to = aws_subnet.public["us-east-1a"]
  id = "subnet-0abc123"
}

import {
  to = aws_subnet.public["us-east-1b"]
  id = "subnet-0def456"
}

import {
  to = aws_security_group.web
  id = "sg-0abc123"
}
```

Run `terraform plan` to see what will be imported and what configuration changes are needed.

### Import into Modules

```hcl
import {
  to = module.vpc.aws_vpc.main
  id = "vpc-0abc123def456"
}
```

---

## Generating Configuration

Terraform 1.5+ can automatically generate resource configuration from imported resources.

### Generate Config for Import Blocks

```bash
terraform plan -generate-config-out=generated.tf
```

This reads all `import` blocks, fetches the current resource state from AWS, and writes the corresponding Terraform configuration to `generated.tf`.

### Workflow

1. Write import blocks:

```hcl
# imports.tf
import {
  to = aws_instance.web
  id = "i-0abc123def456"
}

import {
  to = aws_security_group.web
  id = "sg-0abc123"
}
```

2. Generate configuration:

```bash
terraform plan -generate-config-out=generated.tf
```

3. Review and refine `generated.tf`:

```hcl
# generated.tf (auto-generated, needs cleanup)
resource "aws_instance" "web" {
  ami                    = "ami-0abcdef1234567890"
  instance_type          = "t3.micro"
  key_name               = "deployer"
  subnet_id              = "subnet-0abc123"
  vpc_security_group_ids = ["sg-0abc123"]

  tags = {
    Name = "web-server"
  }

  # ... many more attributes, some of which may need to be removed
}
```

4. Clean up the generated configuration:
   - Remove computed-only attributes (they will be populated from state)
   - Replace hardcoded IDs with references to other resources or variables
   - Add appropriate variable declarations
   - Organize into proper file structure

5. Run `terraform plan` to verify no changes:

```bash
terraform plan
# No changes. Your infrastructure matches the configuration.
```

6. Remove the import blocks (they are no longer needed after successful import).

---

## Step-by-Step Import Workflow

### Step 1: Inventory Existing Resources

Use AWS CLI to list resources you want to import:

```bash
# List VPCs
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table

# List instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,Tags[?Key==`Name`].Value|[0]]' --output table

# List S3 buckets
aws s3api list-buckets --query 'Buckets[*].Name' --output table

# List RDS instances
aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceClass,Engine]' --output table
```

### Step 2: Write Import Blocks

Create an `imports.tf` file:

```hcl
import {
  to = aws_vpc.main
  id = "vpc-0abc123def456"
}

import {
  to = aws_instance.web
  id = "i-0abc123def456"
}
```

### Step 3: Generate Configuration

```bash
terraform init
terraform plan -generate-config-out=generated_resources.tf
```

### Step 4: Review and Refactor

Move generated resources into appropriate files, replace hardcoded values with variables, and add proper structure:

```hcl
# Before (generated)
resource "aws_instance" "web" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
  subnet_id     = "subnet-0abc123"
}

# After (refactored)
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.private[0].id

  tags = local.common_tags
}
```

### Step 5: Verify

```bash
terraform plan
# No changes. Your infrastructure matches the configuration.
```

### Step 6: Clean Up

Remove the `imports.tf` file and `generated_resources.tf` (if you moved everything).

---

## Bulk Import Strategies

### Strategy 1: Script-Based Import

Generate import commands from AWS CLI output:

```bash
#!/bin/bash
# generate-imports.sh

# Import all S3 buckets
for bucket in $(aws s3api list-buckets --query 'Buckets[*].Name' --output text); do
  echo "import {"
  echo "  to = aws_s3_bucket.buckets[\"${bucket}\"]"
  echo "  id = \"${bucket}\""
  echo "}"
done > imports.tf
```

### Strategy 2: Terraformer

[Terraformer](https://github.com/GoogleCloudPlatform/terraformer) generates Terraform configuration and state from existing infrastructure:

```bash
# Install
brew install terraformer

# Import all EC2 instances
terraformer import aws --resources=ec2_instance --regions=us-east-1

# Import specific resources
terraformer import aws --resources=vpc,subnet,security_group --regions=us-east-1

# Import with filters
terraformer import aws --resources=s3 --filter="Name=tags.Environment;Value=production"
```

Terraformer generates both `.tf` files and a `terraform.tfstate` file. Review and refactor the generated code before using it.

### Strategy 3: Import by Tag

Import all resources with a specific tag:

```bash
#!/bin/bash
# import-by-tag.sh

TAG_KEY="ManagedBy"
TAG_VALUE="legacy"

# Find and import EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:${TAG_KEY},Values=${TAG_VALUE}" \
  --query 'Reservations[*].Instances[*].InstanceId' \
  --output text | while read instance_id; do
    echo "import {"
    echo "  to = aws_instance.legacy[\"${instance_id}\"]"
    echo "  id = \"${instance_id}\""
    echo "}"
done >> imports.tf
```

### Strategy 4: Incremental Import

For large environments, import in phases:

1. **Phase 1**: Networking (VPCs, subnets, route tables, NAT gateways)
2. **Phase 2**: Security (security groups, IAM roles, KMS keys)
3. **Phase 3**: Compute (EC2 instances, ASGs, load balancers)
4. **Phase 4**: Data (RDS, ElastiCache, S3)
5. **Phase 5**: Remaining services (CloudWatch, SNS, SQS)

---

## Common Resource Import Examples

### VPC and Networking

```bash
# VPC
terraform import aws_vpc.main vpc-0abc123

# Subnets
terraform import 'aws_subnet.public[0]' subnet-0abc123
terraform import 'aws_subnet.private[0]' subnet-0def456

# Internet Gateway
terraform import aws_internet_gateway.main igw-0abc123

# NAT Gateway
terraform import aws_nat_gateway.main nat-0abc123

# Route Table
terraform import aws_route_table.private rt-0abc123

# Route Table Association
terraform import aws_route_table_association.private_a rtbassoc-0abc123
```

### EC2

```bash
# Instance
terraform import aws_instance.web i-0abc123def456

# Security Group
terraform import aws_security_group.web sg-0abc123

# Security Group Rule (more complex ID)
terraform import aws_security_group_rule.https sg-0abc123_ingress_tcp_443_443_0.0.0.0/0

# Key Pair
terraform import aws_key_pair.deployer deployer

# EIP
terraform import aws_eip.web eipalloc-0abc123
```

### RDS

```bash
# DB Instance
terraform import aws_db_instance.main my-database

# DB Subnet Group
terraform import aws_db_subnet_group.main my-db-subnet-group

# DB Parameter Group
terraform import aws_db_parameter_group.main my-param-group
```

### S3

```bash
# Bucket
terraform import aws_s3_bucket.data my-data-bucket

# Bucket Policy
terraform import aws_s3_bucket_policy.data my-data-bucket

# Bucket Versioning
terraform import aws_s3_bucket_versioning.data my-data-bucket

# Bucket Encryption
terraform import aws_s3_bucket_server_side_encryption_configuration.data my-data-bucket
```

### IAM

```bash
# Role
terraform import aws_iam_role.app my-app-role

# Policy
terraform import aws_iam_policy.app arn:aws:iam::123456789012:policy/my-policy

# Role Policy Attachment
terraform import aws_iam_role_policy_attachment.app my-app-role/arn:aws:iam::123456789012:policy/my-policy

# Instance Profile
terraform import aws_iam_instance_profile.app my-instance-profile
```

---

## Common Pitfalls

### 1. Configuration Mismatch After Import

Import only updates state, not your configuration. If your `.tf` files do not match the real resource, `terraform plan` shows changes:

```bash
terraform plan
# ~ aws_instance.web
#   ~ instance_type = "t3.micro" -> "t3.small"  # Your config says t3.small but reality is t3.micro
```

**Fix**: Update your configuration to match the imported resource, then plan again until you see no changes.

### 2. Missing Required Attributes

Generated config may omit attributes that Terraform requires but the API does not return:

```
Error: Missing required argument
  "subnet_id" is required but was not found in the imported resource.
```

**Fix**: Manually add the missing attributes to your configuration.

### 3. Importing Dependent Resources

Resources often have dependencies. Import them in the correct order:

```
1. VPC first
2. Subnets (depend on VPC)
3. Security Groups (depend on VPC)
4. Instances (depend on subnets and security groups)
```

### 4. State Conflicts

If you import a resource that already exists in another Terraform state:

- The resource is now managed by two Terraform configurations
- Both will try to modify/destroy it
- **Fix**: Remove it from one state with `terraform state rm`

### 5. Read-Only Attributes in Config

Generated configuration may include read-only attributes that cannot be set:

```
Error: Attribute "arn" is read-only and cannot be set in configuration.
```

**Fix**: Remove computed/read-only attributes from your configuration. Keep only configurable attributes.

### 6. Sensitive Attributes

Imported resources may contain sensitive values (passwords, keys) that are now in your state file. Ensure your state is encrypted.

### 7. Resource ID Format

Each resource type has a specific ID format. Check the provider documentation for the correct import ID:

```bash
# Some IDs are simple strings
terraform import aws_s3_bucket.b my-bucket

# Some are compound
terraform import aws_security_group_rule.r sg-xxx_ingress_tcp_443_443_0.0.0.0/0

# Some use ARNs
terraform import aws_iam_policy.p arn:aws:iam::123456789012:policy/name

# Some use slashes
terraform import aws_iam_role_policy_attachment.a role-name/policy-arn
```

---

## Post-Import Verification

### Step 1: Plan Should Show No Changes

```bash
terraform plan
# No changes. Your infrastructure matches the configuration.
```

If changes appear, update your configuration to match the real resource.

### Step 2: Verify State

```bash
# List all imported resources
terraform state list

# Show details of specific resources
terraform state show aws_instance.web
```

### Step 3: Test Non-Destructively

```bash
# Refresh to verify state matches reality
terraform apply -refresh-only
```

### Step 4: Validate Configuration

```bash
terraform validate
terraform fmt -check
```

---

## Best Practices

### 1. Import to a Separate Branch

Work on imports in a feature branch. Get the plan to show zero changes before merging.

### 2. Back Up State Before Importing

```bash
terraform state pull > pre_import_backup.json
```

### 3. Use Import Blocks Over CLI Import

Import blocks are reviewable, repeatable, and support config generation. Prefer them for Terraform 1.5+.

### 4. Clean Up Generated Code

Auto-generated configuration is verbose. Refactor it to use variables, locals, modules, and references before committing.

### 5. Import in Small Batches

Do not try to import 500 resources at once. Import in logical groups (networking, then compute, then databases) and verify each group before proceeding.

### 6. Document What You Imported

Keep a record of what was imported, from where, and when. This helps with future troubleshooting.

### 7. Add Lifecycle Blocks for Protection

After importing production resources, add protection:

```hcl
resource "aws_db_instance" "main" {
  # ...
  lifecycle {
    prevent_destroy = true
  }
}
```

---

## Next Steps

- [Moved Blocks](moved-blocks.md) for refactoring after import
- [State Management](../01-terraform-basics/state-management.md) for state operations
- [Terraform CLI Commands](../01-terraform-basics/terraform-cli-commands.md) for the import command reference
