# Data Sources

## Table of Contents

- [What are Data Sources](#what-are-data-sources)
- [Data Source Syntax](#data-source-syntax)
- [Common AWS Data Sources](#common-aws-data-sources)
- [Filtering Data Sources](#filtering-data-sources)
- [Data Source Dependencies](#data-source-dependencies)
- [Data Sources vs Resources](#data-sources-vs-resources)
- [External Data Source](#external-data-source)
- [Remote State Data Source](#remote-state-data-source)
- [Data Source Patterns](#data-source-patterns)
- [Best Practices](#best-practices)

---

## What are Data Sources

Data sources allow Terraform to read information from external sources and use that information in your configuration. Unlike resources, data sources do not create or manage anything. They fetch existing data.

Common uses:

- Look up the latest AMI for an operating system
- Read the current AWS account ID and region
- Fetch VPC and subnet details from existing infrastructure
- Read secrets from AWS Secrets Manager or SSM Parameter Store
- Query an existing S3 bucket's properties

Data sources are refreshed on every `terraform plan` and `terraform apply`, ensuring your configuration always references current values.

---

## Data Source Syntax

```hcl
data "<provider>_<type>" "<local_name>" {
  # Filter/query arguments
  argument = value

  # Optional: explicit dependency
  depends_on = [resource.name]
}

# Reference: data.<provider>_<type>.<local_name>.<attribute>
```

### Basic Example

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id    # Use the looked-up AMI ID
  instance_type = "t3.micro"
}
```

---

## Common AWS Data Sources

### aws_caller_identity

Returns details about the IAM identity making the API calls:

```hcl
data "aws_caller_identity" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
  # e.g., "123456789012"
}

output "caller_arn" {
  value = data.aws_caller_identity.current.arn
  # e.g., "arn:aws:iam::123456789012:user/terraform"
}

output "user_id" {
  value = data.aws_caller_identity.current.user_id
}
```

### aws_region

Returns information about the current region:

```hcl
data "aws_region" "current" {}

output "region_name" {
  value = data.aws_region.current.name
  # e.g., "us-east-1"
}

output "region_description" {
  value = data.aws_region.current.description
  # e.g., "US East (N. Virginia)"
}
```

### aws_partition

Returns the partition (useful for GovCloud and China regions):

```hcl
data "aws_partition" "current" {}

# Build ARNs that work in any partition
locals {
  s3_arn_prefix = "arn:${data.aws_partition.current.partition}:s3:::"
}

# In standard AWS:  arn:aws:s3:::
# In GovCloud:      arn:aws-us-gov:s3:::
# In China:         arn:aws-cn:s3:::
```

### aws_availability_zones

Lists available AZs in the current region:

```hcl
data "aws_availability_zones" "available" {
  state = "available"

  # Exclude Local Zones
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

resource "aws_subnet" "private" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
}
```

### aws_vpc

Look up an existing VPC:

```hcl
# By tag
data "aws_vpc" "main" {
  tags = {
    Name = "production-vpc"
  }
}

# By ID
data "aws_vpc" "specific" {
  id = "vpc-0abc123def456"
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

output "vpc_cidr" {
  value = data.aws_vpc.main.cidr_block
}
```

### aws_subnets

Look up multiple subnets:

```hcl
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  tags = {
    Tier = "private"
  }
}

# Use the subnet IDs
resource "aws_lb" "main" {
  name               = "app-lb"
  internal           = true
  load_balancer_type = "application"
  subnets            = data.aws_subnets.private.ids
}
```

### aws_subnet

Look up a single subnet:

```hcl
data "aws_subnet" "selected" {
  id = "subnet-0abc123"
}

# Or filter by properties
data "aws_subnet" "public_a" {
  vpc_id            = data.aws_vpc.main.id
  availability_zone = "us-east-1a"

  tags = {
    Tier = "public"
  }
}
```

### aws_ami

Look up an AMI:

```hcl
# Latest Amazon Linux 2023
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

# Latest ECS-optimized AMI
data "aws_ami" "ecs_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}
```

### aws_iam_policy_document

Generates an IAM policy document in JSON. This is the preferred way to write IAM policies in Terraform (instead of raw JSON strings):

```hcl
data "aws_iam_policy_document" "s3_read" {
  statement {
    sid    = "AllowS3Read"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]

    resources = [
      aws_s3_bucket.data.arn,
      "${aws_s3_bucket.data.arn}/*",
    ]
  }

  statement {
    sid    = "DenyUnencryptedUploads"
    effect = "Deny"

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.data.arn}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }
}

resource "aws_iam_policy" "s3_read" {
  name   = "s3-read-access"
  policy = data.aws_iam_policy_document.s3_read.json
}
```

### aws_secretsmanager_secret_version

Read a secret from Secrets Manager:

```hcl
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = "prod/database/credentials"
}

locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
}

resource "aws_db_instance" "main" {
  username = local.db_creds["username"]
  password = local.db_creds["password"]
  # ...
}
```

### aws_ssm_parameter

Read from Systems Manager Parameter Store:

```hcl
data "aws_ssm_parameter" "db_endpoint" {
  name = "/prod/database/endpoint"
}

data "aws_ssm_parameter" "api_key" {
  name            = "/prod/api/key"
  with_decryption = true
}
```

---

## Filtering Data Sources

Many data sources support `filter` blocks that correspond to the AWS API filters.

### Filter Syntax

```hcl
data "aws_ami" "example" {
  filter {
    name   = "filter-name"          # AWS API filter name
    values = ["value1", "value2"]   # Values to match (OR logic within a filter)
  }

  filter {
    name   = "another-filter"       # Multiple filters use AND logic
    values = ["value"]
  }
}
```

### Common Filter Patterns

```hcl
# Find instances by tag
data "aws_instances" "web_servers" {
  filter {
    name   = "tag:Role"
    values = ["web"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

# Find security groups by VPC
data "aws_security_groups" "web" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "group-name"
    values = ["web-*"]
  }
}

# Find EBS volumes by tag and status
data "aws_ebs_volumes" "backups" {
  filter {
    name   = "tag:Purpose"
    values = ["backup"]
  }

  filter {
    name   = "status"
    values = ["available"]
  }
}
```

---

## Data Source Dependencies

### Implicit Dependencies

Terraform automatically detects dependencies when one data source references another resource:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# This data source depends on the VPC resource
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]   # Implicit dependency
  }
}
```

### Explicit Dependencies

When there is no reference to create an implicit dependency, use `depends_on`:

```hcl
resource "aws_iam_role_policy_attachment" "eks" {
  role       = aws_iam_role.eks.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# The EKS cluster data source should wait for the policy attachment
data "aws_eks_cluster" "main" {
  name = aws_eks_cluster.main.name

  depends_on = [aws_iam_role_policy_attachment.eks]
}
```

### Data Sources and Planning

Data sources are read during the planning phase. If a data source depends on a resource that does not yet exist (will be created in the same apply), Terraform defers reading the data source until the apply phase.

```hcl
resource "aws_vpc" "new" {
  cidr_block = "10.0.0.0/16"
}

# This cannot be read during plan because the VPC doesn't exist yet
# Terraform shows: (known after apply)
data "aws_subnets" "in_new_vpc" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.new.id]
  }
}
```

---

## Data Sources vs Resources

| Aspect | Resource | Data Source |
|--------|----------|-------------|
| Purpose | Create and manage infrastructure | Read existing infrastructure |
| Lifecycle | Create, update, destroy | Read-only (refreshed each plan) |
| State | Stored in state with full attributes | Stored in state as cache |
| Prefix | `resource "type" "name"` | `data "type" "name"` |
| Reference | `type.name.attribute` | `data.type.name.attribute` |

### When to Use Data Sources

- Look up AMI IDs dynamically instead of hardcoding
- Reference existing VPCs, subnets, or security groups
- Read secrets from Secrets Manager or SSM
- Get the current account ID, region, or partition
- Build IAM policy documents
- Query infrastructure managed by a different Terraform configuration

### When NOT to Use Data Sources

- Do not use data sources to look up resources that your own configuration manages. Reference them directly:

```hcl
# BAD: looking up your own resource
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "main" }
}

data "aws_vpc" "main" {  # Unnecessary!
  tags = { Name = "main" }
}

# GOOD: reference directly
resource "aws_subnet" "private" {
  vpc_id = aws_vpc.main.id   # Direct reference
}
```

---

## External Data Source

The `external` data source runs an external program and reads its JSON output. Use it when Terraform does not have a native data source for what you need:

```hcl
data "external" "git_info" {
  program = ["bash", "-c", <<-EOT
    echo '{"sha": "'$(git rev-parse --short HEAD)'", "branch": "'$(git rev-parse --abbrev-ref HEAD)'"}'
  EOT
  ]
}

resource "aws_instance" "web" {
  # ...
  tags = {
    GitSHA    = data.external.git_info.result["sha"]
    GitBranch = data.external.git_info.result["branch"]
  }
}
```

### Requirements

- The program must read JSON from stdin (or ignore it) and write JSON to stdout
- All values in the output JSON must be strings
- Non-zero exit code signals an error

### Custom Script Example

**scripts/lookup.sh**:

```bash
#!/bin/bash
set -e

# Read input from stdin
INPUT=$(cat)
ENVIRONMENT=$(echo "$INPUT" | jq -r '.environment')

# Perform lookup (e.g., from a CMDB or API)
RESULT=$(curl -s "https://api.internal/config/${ENVIRONMENT}")

# Output JSON to stdout
echo "$RESULT"
```

```hcl
data "external" "config" {
  program = ["bash", "${path.module}/scripts/lookup.sh"]

  query = {
    environment = var.environment
  }
}
```

**Caution**: External data sources make your configuration dependent on external tools. They reduce portability and can cause issues in CI/CD environments. Prefer native Terraform data sources whenever possible.

---

## Remote State Data Source

Read outputs from another Terraform state:

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = "mycompany-terraform-state"
    key    = "prod/networking/terraform.tfstate"
    region = "us-east-1"
  }
}

# Use outputs from the network state
resource "aws_instance" "web" {
  subnet_id         = data.terraform_remote_state.network.outputs.private_subnet_ids[0]
  vpc_security_group_ids = [data.terraform_remote_state.network.outputs.web_sg_id]
}
```

### Limitations

- Creates tight coupling between Terraform configurations
- The referenced configuration must expose the needed values as outputs
- Reading state requires access to the backend (IAM permissions)
- If the remote state is deleted or reorganized, this data source breaks

### Alternative: Use Native Data Sources

Instead of reading the VPC ID from remote state, look it up directly:

```hcl
# Instead of terraform_remote_state:
data "aws_vpc" "main" {
  tags = {
    Name        = "production"
    Environment = "prod"
  }
}
```

This is more resilient because it queries the real infrastructure rather than depending on another Terraform state's structure.

---

## Data Source Patterns

### Dynamic AMI Lookup

```hcl
variable "os" {
  type    = string
  default = "ubuntu"
}

locals {
  ami_filters = {
    ubuntu = {
      owners = ["099720109477"]
      name   = "ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"
    }
    amazon_linux = {
      owners = ["amazon"]
      name   = "al2023-ami-2023*-x86_64"
    }
  }
}

data "aws_ami" "selected" {
  most_recent = true
  owners      = local.ami_filters[var.os].owners

  filter {
    name   = "name"
    values = [local.ami_filters[var.os].name]
  }
}
```

### Cross-Account Data Access

```hcl
provider "aws" {
  alias  = "shared_services"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::999888777666:role/ReadOnly"
  }
}

data "aws_ami" "golden_image" {
  provider    = aws.shared_services
  most_recent = true
  owners      = ["999888777666"]

  filter {
    name   = "tag:Approved"
    values = ["true"]
  }
}
```

### Building Comprehensive IAM Policies

```hcl
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "combined" {
  source_policy_documents = [
    data.aws_iam_policy_document.base_permissions.json,
    data.aws_iam_policy_document.s3_permissions.json,
  ]

  override_policy_documents = [
    data.aws_iam_policy_document.restrictions.json,
  ]
}
```

---

## Best Practices

### 1. Use Data Sources for Dynamic Values

Hardcoded AMI IDs, account IDs, and region names break portability. Use data sources to look them up dynamically.

### 2. Filter Precisely

Broad filters can return unexpected results. Be specific:

```hcl
# Bad: too broad, may match unexpected AMIs
data "aws_ami" "app" {
  most_recent = true
  owners      = ["self"]
}

# Good: specific filters
data "aws_ami" "app" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["myapp-v*"]
  }

  filter {
    name   = "tag:Approved"
    values = ["true"]
  }
}
```

### 3. Use aws_iam_policy_document Instead of JSON Strings

The `aws_iam_policy_document` data source catches errors, supports composition, and is easier to read than heredoc JSON.

### 4. Prefer Native Data Sources Over terraform_remote_state

Native data sources query real infrastructure and do not depend on another Terraform configuration's state file structure.

### 5. Group Data Sources in a Dedicated File

For clarity, place data source lookups in `data.tf`:

```
project/
  main.tf          # Resources
  data.tf          # Data sources
  variables.tf     # Variables
  outputs.tf       # Outputs
```

### 6. Handle Missing Data

When a data source might not find results, use `count` or handle it gracefully:

```hcl
data "aws_vpc" "existing" {
  count = var.create_vpc ? 0 : 1

  tags = {
    Name = var.vpc_name
  }
}

locals {
  vpc_id = var.create_vpc ? aws_vpc.new[0].id : data.aws_vpc.existing[0].id
}
```

---

## Next Steps

- [Functions and Expressions](functions-and-expressions.md) for transforming data source outputs
- [Variables and Outputs](variables-and-outputs.md) for passing data between modules
- [Dependency Management](../03-terraform-advanced/dependency-management.md) for complex dependency patterns
