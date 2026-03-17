# Modules

## Table of Contents

- [What are Modules](#what-are-modules)
- [Module Structure](#module-structure)
- [Creating a Module](#creating-a-module)
- [Calling a Module](#calling-a-module)
- [Module Sources](#module-sources)
- [Module Versioning](#module-versioning)
- [Module Composition](#module-composition)
- [Passing Providers to Modules](#passing-providers-to-modules)
- [Module Best Practices](#module-best-practices)
- [Publishing Modules](#publishing-modules)
- [Registry Modules](#registry-modules)

---

## What are Modules

A module is a container for multiple Terraform resources that are used together. Every Terraform configuration is a module. The root module is the set of `.tf` files in the directory where you run `terraform plan` and `terraform apply`. Child modules are modules called from within the root module.

Modules provide:

- **Encapsulation**: Hide implementation details behind a clean interface
- **Reusability**: Write once, use in multiple environments and projects
- **Consistency**: Enforce organizational standards through shared modules
- **Abstraction**: Expose simple inputs for complex infrastructure patterns

```
root-module/
  main.tf              <-- calls child modules
  variables.tf
  outputs.tf
  modules/
    vpc/               <-- child module
      main.tf
      variables.tf
      outputs.tf
    compute/           <-- child module
      main.tf
      variables.tf
      outputs.tf
```

---

## Module Structure

A well-structured module follows this layout:

```
modules/vpc/
  main.tf           # Primary resources
  variables.tf      # Input variables (the module's interface)
  outputs.tf        # Output values (what the module exposes)
  versions.tf       # Required providers and Terraform version
  README.md         # Documentation
  examples/         # Example usage
    basic/
      main.tf
    complete/
      main.tf
  tests/            # Test files
    basic.tftest.hcl
```

### Minimal Module Example

**modules/s3-bucket/variables.tf**:

```hcl
variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "enable_versioning" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply"
  type        = map(string)
  default     = {}
}
```

**modules/s3-bucket/main.tf**:

```hcl
resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name

  tags = merge(
    {
      Name        = var.bucket_name
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

**modules/s3-bucket/outputs.tf**:

```hcl
output "bucket_id" {
  description = "The name of the bucket"
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "The ARN of the bucket"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name"
  value       = aws_s3_bucket.this.bucket_domain_name
}
```

**modules/s3-bucket/versions.tf**:

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
```

---

## Creating a Module

### Design Principles

1. **Single Responsibility**: Each module should manage one logical component (a VPC, an EKS cluster, a Lambda function).
2. **Reasonable Defaults**: Provide sensible defaults for optional variables so the module works out of the box.
3. **Minimal Required Inputs**: Only require inputs that genuinely vary between uses.
4. **Complete Outputs**: Export all attributes that consumers might need.
5. **No Hardcoded Values**: Everything that might change should be a variable.

### Module with for_each and count

Modules support `count` and `for_each` (Terraform 0.13+):

```hcl
module "buckets" {
  source   = "./modules/s3-bucket"
  for_each = toset(["logs", "artifacts", "backups"])

  bucket_name = "${var.project}-${each.key}-${var.environment}"
  environment = var.environment
}

# Access outputs
output "bucket_arns" {
  value = { for k, v in module.buckets : k => v.bucket_arn }
}
```

---

## Calling a Module

```hcl
module "data_bucket" {
  source = "./modules/s3-bucket"

  bucket_name       = "myapp-data-production"
  environment       = "production"
  enable_versioning = true

  tags = {
    Team    = "data-engineering"
    Project = "analytics"
  }
}

# Use the module's outputs
resource "aws_iam_policy" "data_access" {
  name = "data-bucket-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${module.data_bucket.bucket_arn}/*"
      }
    ]
  })
}
```

---

## Module Sources

Terraform supports many module source types:

### Local Path

```hcl
module "vpc" {
  source = "./modules/vpc"
}

module "shared" {
  source = "../shared-modules/vpc"
}
```

### Terraform Registry

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.4.0"
}
```

### GitHub

```hcl
# HTTPS
module "vpc" {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v5.4.0"
}

# SSH
module "vpc" {
  source = "git@github.com:terraform-aws-modules/terraform-aws-vpc.git?ref=v5.4.0"
}
```

### Generic Git Repository

```hcl
module "vpc" {
  source = "git::https://gitlab.com/myorg/terraform-modules.git//vpc?ref=v1.0.0"
}
```

### S3 Bucket

```hcl
module "vpc" {
  source = "s3::https://s3-us-east-1.amazonaws.com/my-modules/vpc.zip"
}
```

### GCS Bucket

```hcl
module "vpc" {
  source = "gcs::https://www.googleapis.com/storage/v1/my-modules/vpc.zip"
}
```

### Subdirectory Within a Repository

Use `//` to specify a subdirectory:

```hcl
module "vpc" {
  source = "git::https://github.com/myorg/infra-modules.git//modules/vpc?ref=v2.0.0"
}
```

---

## Module Versioning

### Registry Modules

Registry modules support version constraints:

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"    # Any 5.x version
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = ">= 19.0, < 21.0"
}
```

### Git Modules

Use the `ref` argument to pin a specific version:

```hcl
# Pin to a tag
module "vpc" {
  source = "git::https://github.com/myorg/modules.git//vpc?ref=v2.1.0"
}

# Pin to a branch
module "vpc" {
  source = "git::https://github.com/myorg/modules.git//vpc?ref=main"
}

# Pin to a commit SHA (most precise)
module "vpc" {
  source = "git::https://github.com/myorg/modules.git//vpc?ref=abc1234"
}
```

**Always pin module versions.** Unpinned modules can break your infrastructure when upstream changes are pushed.

---

## Module Composition

### Pattern: Root Module Composing Child Modules

```hcl
# root module: main.tf

module "vpc" {
  source = "./modules/vpc"

  cidr_block  = "10.0.0.0/16"
  environment = var.environment
}

module "security" {
  source = "./modules/security-groups"

  vpc_id      = module.vpc.vpc_id
  environment = var.environment
}

module "compute" {
  source = "./modules/compute"

  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  security_group_id = module.security.app_sg_id
  environment       = var.environment
}

module "database" {
  source = "./modules/rds"

  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.database_subnet_ids
  security_group_id = module.security.db_sg_id
  environment       = var.environment
}
```

### Pattern: Wrapper Module

A wrapper module composes multiple registry modules into an opinionated bundle:

```hcl
# modules/web-stack/main.tf

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = "${var.app_name}-alb"
  load_balancer_type = "application"
  vpc_id             = var.vpc_id
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.alb.id]
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 7.0"

  name            = "${var.app_name}-asg"
  min_size        = var.min_instances
  max_size        = var.max_instances
  desired_capacity = var.desired_instances
  vpc_zone_identifier = var.private_subnet_ids

  target_group_arns = module.alb.target_group_arns
}
```

Consumers call the wrapper with a simple interface:

```hcl
module "web" {
  source = "./modules/web-stack"

  app_name          = "myapp"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  min_instances     = 2
  max_instances     = 10
  desired_instances = 3
}
```

---

## Passing Providers to Modules

By default, a module inherits the default provider from the calling module. To pass a specific provider:

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "eu"
  region = "eu-west-1"
}

module "eu_vpc" {
  source = "./modules/vpc"

  providers = {
    aws = aws.eu
  }

  cidr_block = "10.1.0.0/16"
}
```

For modules that need multiple providers:

```hcl
# The module declares required providers with configuration_aliases
# modules/cross-region/versions.tf
terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = [aws.primary, aws.replica]
    }
  }
}

# Calling the module
module "cross_region_replica" {
  source = "./modules/cross-region"

  providers = {
    aws.primary = aws
    aws.replica = aws.eu
  }
}
```

---

## Module Best Practices

### 1. Use Consistent Variable Naming

```hcl
# Module variables should be clear without the module context
variable "vpc_id" {}            # good - clear what it is
variable "id" {}                # bad - ambiguous
variable "the_vpc_id" {}        # bad - unnecessary prefix
```

### 2. Validate Inputs

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "cidr_block" {
  type = string
  validation {
    condition     = can(cidrhost(var.cidr_block, 0))
    error_message = "Must be a valid CIDR block."
  }
}
```

### 3. Use Lifecycle Meta-Arguments Carefully

```hcl
resource "aws_instance" "this" {
  # ...

  lifecycle {
    create_before_destroy = true    # Zero-downtime replacements
    ignore_changes        = [tags]  # Ignore external tag changes
  }
}
```

### 4. Output Everything Useful

Expose all attributes that consumers might need. It is easier to add outputs from the start than to release a new module version later.

### 5. Document with Descriptions

Every variable and output should have a `description`:

```hcl
variable "instance_type" {
  description = "EC2 instance type for the application servers"
  type        = string
  default     = "t3.micro"
}

output "load_balancer_dns" {
  description = "DNS name of the application load balancer"
  value       = aws_lb.this.dns_name
}
```

### 6. Do Not Hardcode Provider Configuration

Modules should not contain `provider` blocks (except for `required_providers`). Let the calling module configure the provider.

### 7. Use Moved Blocks for Refactoring

When renaming resources within a module, use `moved` blocks to avoid destruction:

```hcl
moved {
  from = aws_instance.server
  to   = aws_instance.application
}
```

### 8. Keep Modules Focused

A module managing a VPC should not also create EC2 instances. If you find a module doing too many things, split it into smaller, composable modules.

---

## Publishing Modules

### Terraform Registry

To publish a module to the public Terraform Registry:

1. **Naming**: Repository must be named `terraform-<PROVIDER>-<NAME>` (e.g., `terraform-aws-vpc`).
2. **Structure**: Must have `main.tf`, `variables.tf`, `outputs.tf` at the root.
3. **Versioning**: Use Git tags for versions (e.g., `v1.0.0`).
4. **Documentation**: Must include a `README.md`.

```
terraform-aws-vpc/
  main.tf
  variables.tf
  outputs.tf
  versions.tf
  README.md
  examples/
    basic/
      main.tf
    complete/
      main.tf
  modules/              # Submodules
    subnets/
      main.tf
      variables.tf
      outputs.tf
```

### Private Registry (Terraform Cloud)

```bash
# Publish via Terraform Cloud UI or API
# Modules in the private registry are referenced as:
module "vpc" {
  source  = "app.terraform.io/my-org/vpc/aws"
  version = "~> 2.0"
}
```

### Artifactory or S3

Store module archives in an artifact repository:

```bash
# Package the module
cd modules/vpc && zip -r vpc-v1.0.0.zip .

# Upload to S3
aws s3 cp vpc-v1.0.0.zip s3://my-terraform-modules/vpc/v1.0.0/vpc.zip
```

---

## Registry Modules

### Popular AWS Registry Modules

| Module | Source | Purpose |
|--------|--------|---------|
| VPC | `terraform-aws-modules/vpc/aws` | Complete VPC with subnets |
| EKS | `terraform-aws-modules/eks/aws` | Elastic Kubernetes Service |
| RDS | `terraform-aws-modules/rds/aws` | Relational Database Service |
| S3 | `terraform-aws-modules/s3-bucket/aws` | S3 with best practices |
| ALB | `terraform-aws-modules/alb/aws` | Application Load Balancer |
| Lambda | `terraform-aws-modules/lambda/aws` | Lambda functions |
| IAM | `terraform-aws-modules/iam/aws` | IAM roles and policies |
| Security Group | `terraform-aws-modules/security-group/aws` | Security groups |

### Using a Registry Module

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.4.0"

  name = "production-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = false
  enable_dns_hostnames = true

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Evaluating Registry Modules

Before using a registry module, check:

- **Downloads**: High download count indicates community trust
- **Verified badge**: Verified modules are maintained by trusted organizations
- **Last updated**: Recently updated modules are more likely to support current provider versions
- **Open issues**: Check for unresolved bugs
- **Examples**: Good modules include working examples
- **Submodules**: Some modules include submodules for specific use cases

---

## Next Steps

- [Variables and Outputs](variables-and-outputs.md) for detailed variable management
- [Moved Blocks](../03-terraform-advanced/moved-blocks.md) for refactoring modules safely
- [Testing](../03-terraform-advanced/testing.md) for testing modules
