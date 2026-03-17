# HCL Syntax — HashiCorp Configuration Language

## Table of Contents

- [Overview](#overview)
- [Files and Encoding](#files-and-encoding)
- [Blocks](#blocks)
- [Arguments and Attributes](#arguments-and-attributes)
- [Comments](#comments)
- [Data Types](#data-types)
- [Expressions](#expressions)
- [Operators](#operators)
- [String Templates](#string-templates)
- [Heredoc Strings](#heredoc-strings)
- [References](#references)
- [JSON Compatibility](#json-compatibility)
- [Best Practices](#best-practices)

---

## Overview

HashiCorp Configuration Language (HCL) is a structured configuration language designed to be both human-readable and machine-parseable. Terraform uses HCL as its primary language for defining infrastructure. HCL strikes a balance between JSON (easy for machines) and YAML (easy for humans) while adding programming constructs like variables, functions, and expressions.

HCL files use the `.tf` extension. Variable definition files use `.tfvars`.

---

## Files and Encoding

- Terraform configuration files must be UTF-8 encoded.
- Files use the `.tf` extension for HCL or `.tf.json` for JSON format.
- Terraform loads all `.tf` files in the working directory, so you can split configuration across multiple files.
- File names are arbitrary, but conventions like `main.tf`, `variables.tf`, `outputs.tf`, and `providers.tf` make projects navigable.
- Terraform processes files in lexicographic order but since declarations are not order-dependent, file organization is purely for readability.

---

## Blocks

Blocks are the fundamental structural element of HCL. A block has a type, zero or more labels, and a body containing arguments and nested blocks.

```hcl
block_type "label_1" "label_2" {
  # Block body
  argument = value

  nested_block {
    another_argument = value
  }
}
```

### Common Block Types in Terraform

```hcl
# Terraform settings block (no labels)
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "my-terraform-state"
    key    = "global/terraform.tfstate"
    region = "us-east-1"
  }
}

# Provider block (one label: provider name)
provider "aws" {
  region = "us-east-1"
}

# Resource block (two labels: resource type, local name)
resource "aws_instance" "web_server" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
}

# Data source block (two labels: data source type, local name)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
}

# Variable block (one label: variable name)
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# Output block (one label: output name)
output "instance_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

# Locals block (no labels)
locals {
  common_tags = {
    Project     = "web-app"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Module block (one label: module name)
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.4.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```

---

## Arguments and Attributes

### Arguments

Arguments assign a value to a name within a block:

```hcl
resource "aws_instance" "example" {
  ami           = "ami-0abcdef1234567890"  # argument
  instance_type = "t3.micro"               # argument
  monitoring    = true                     # argument

  tags = {                                 # argument with map value
    Name = "example"
  }
}
```

### Attributes

Attributes are values exported by resources after creation. You reference them to pass information between resources:

```hcl
# The aws_instance resource exports attributes like id, public_ip, arn
resource "aws_eip" "web" {
  instance = aws_instance.example.id       # referencing an attribute
}
```

---

## Comments

HCL supports three comment styles:

```hcl
# Single-line comment (hash) — most common style

// Single-line comment (double slash) — also supported

/*
  Multi-line comment
  Spans multiple lines
  Useful for temporarily disabling blocks
*/
```

Convention: Use `#` for all single-line comments.

---

## Data Types

### Primitive Types

```hcl
variable "example_string" {
  type    = string
  default = "hello world"
}

variable "example_number" {
  type    = number
  default = 42          # integers
  # default = 3.14      # floats also supported
}

variable "example_bool" {
  type    = bool
  default = true        # true or false
}
```

### Collection Types

#### List (Ordered sequence of values, same type)

```hcl
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# Access by index (zero-based)
# var.availability_zones[0] => "us-east-1a"

variable "ports" {
  type    = list(number)
  default = [80, 443, 8080]
}
```

#### Set (Unordered unique values, same type)

```hcl
variable "allowed_cidrs" {
  type    = set(string)
  default = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

# Sets automatically deduplicate values
# Cannot access by index (unordered)
```

#### Map (Key-value pairs, same value type)

```hcl
variable "instance_types" {
  type = map(string)
  default = {
    dev     = "t3.micro"
    staging = "t3.medium"
    prod    = "t3.large"
  }
}

# Access by key
# var.instance_types["dev"] => "t3.micro"
# var.instance_types.dev    => "t3.micro" (dot notation)
```

#### Tuple (Ordered sequence, mixed types)

```hcl
variable "mixed_values" {
  type    = tuple([string, number, bool])
  default = ["hello", 42, true]
}

# Access by index
# var.mixed_values[0] => "hello"
# var.mixed_values[1] => 42
```

### Structural Types

#### Object (Named attributes with specified types)

```hcl
variable "server_config" {
  type = object({
    name          = string
    instance_type = string
    disk_size_gb  = number
    monitoring    = bool
    tags          = map(string)
  })

  default = {
    name          = "web-server"
    instance_type = "t3.micro"
    disk_size_gb  = 50
    monitoring    = true
    tags = {
      Environment = "dev"
    }
  }
}
```

#### Nested and Complex Types

```hcl
variable "vpc_config" {
  type = object({
    cidr_block = string
    subnets = list(object({
      cidr_block        = string
      availability_zone = string
      public            = bool
    }))
    tags = map(string)
  })

  default = {
    cidr_block = "10.0.0.0/16"
    subnets = [
      {
        cidr_block        = "10.0.1.0/24"
        availability_zone = "us-east-1a"
        public            = true
      },
      {
        cidr_block        = "10.0.2.0/24"
        availability_zone = "us-east-1b"
        public            = false
      }
    ]
    tags = {
      Project = "main"
    }
  }
}
```

### The `any` Type

```hcl
variable "flexible_map" {
  type    = map(any)
  default = {
    name = "example"
    count = "3"   # Note: all values become strings in map(any)
  }
}
```

### Null

The special value `null` represents absence of a value. When a resource argument is set to `null`, Terraform behaves as if the argument was omitted:

```hcl
resource "aws_instance" "example" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
  key_name      = var.enable_ssh ? var.key_name : null  # conditionally omit
}
```

---

## Expressions

### Arithmetic

```hcl
locals {
  total_storage = var.disk_count * var.disk_size   # multiplication
  doubled       = var.count * 2                     # scaling
  remaining     = var.total - var.used              # subtraction
  share         = var.total / var.parts             # division
  remainder     = var.total % var.parts             # modulo
}
```

### Conditional Expressions

```hcl
locals {
  instance_type = var.environment == "production" ? "t3.large" : "t3.micro"
  enable_nat    = var.environment != "dev" ? true : false
}

resource "aws_instance" "web" {
  instance_type = local.instance_type
  monitoring    = var.environment == "production" ? true : false
}
```

### For Expressions

```hcl
# Transform a list
locals {
  upper_names = [for name in var.names : upper(name)]
  # ["alice", "bob"] => ["ALICE", "BOB"]

  # Filter a list
  long_names = [for name in var.names : name if length(name) > 3]

  # Transform a map
  tag_map = { for k, v in var.raw_tags : lower(k) => lower(v) }

  # List to map
  instance_map = { for inst in aws_instance.web : inst.id => inst.private_ip }

  # Nested for
  subnet_pairs = flatten([
    for vpc_key, vpc in var.vpcs : [
      for subnet_key, subnet in vpc.subnets : {
        vpc_key    = vpc_key
        subnet_key = subnet_key
        cidr       = subnet.cidr
      }
    ]
  ])
}
```

### Splat Expressions

```hcl
# These two are equivalent:
# Full form
output "instance_ids_for" {
  value = [for inst in aws_instance.web : inst.id]
}

# Splat expression (shorter)
output "instance_ids_splat" {
  value = aws_instance.web[*].id
}

# Attribute splat for single resources with count
output "all_arns" {
  value = aws_iam_user.users[*].arn
}
```

---

## Operators

### Comparison Operators

```hcl
# ==  Equal
# !=  Not equal
# <   Less than
# >   Greater than
# <=  Less than or equal
# >=  Greater than or equal

locals {
  is_production = var.environment == "production"
  needs_scaling = var.cpu_usage > 80
}
```

### Logical Operators

```hcl
# &&  AND
# ||  OR
# !   NOT

locals {
  enable_monitoring = var.environment == "production" && var.monitoring_enabled
  needs_attention   = var.error_count > 0 || var.warning_count > 10
  is_not_dev        = !var.is_development
}
```

---

## String Templates

### Interpolation

Embed expressions within strings using `${}`:

```hcl
locals {
  greeting    = "Hello, ${var.name}!"
  bucket_name = "app-${var.environment}-${var.region}-data"
  resource_id = "arn:aws:s3:::${local.bucket_name}"
}
```

### Directive Templates

Use `%{}` for control flow within strings:

```hcl
locals {
  # Conditional
  message = "Server is %{if var.is_production}in production%{else}in development%{endif}"

  # Loop
  hosts_entries = <<-EOT
  %{for addr in var.ip_addresses}
  ${addr} host-${index(var.ip_addresses, addr)}.example.com
  %{endfor}
  EOT
}
```

---

## Heredoc Strings

For multi-line strings, use heredoc syntax:

### Standard Heredoc

```hcl
variable "policy" {
  default = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::my-bucket/*"
    }
  ]
}
EOT
}
```

### Indented Heredoc (<<-)

The `<<-` variant strips leading whitespace, letting you indent the content with your code:

```hcl
resource "aws_iam_policy" "example" {
  name   = "example-policy"
  policy = <<-EOT
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": "s3:GetObject",
          "Resource": "arn:aws:s3:::my-bucket/*"
        }
      ]
    }
  EOT
}
```

With `<<-`, Terraform finds the line with the least leading whitespace and strips that amount from all lines, so your output is properly formatted regardless of code indentation.

---

## References

### Resource References

```hcl
# Format: <resource_type>.<local_name>.<attribute>
aws_instance.web.id
aws_instance.web.public_ip
aws_vpc.main.cidr_block
```

### Data Source References

```hcl
# Format: data.<data_source_type>.<local_name>.<attribute>
data.aws_ami.ubuntu.id
data.aws_vpc.default.id
data.aws_caller_identity.current.account_id
```

### Variable References

```hcl
var.instance_type
var.tags["Environment"]
var.subnets[0]
```

### Local Value References

```hcl
local.common_tags
local.bucket_name
```

### Module Output References

```hcl
module.vpc.vpc_id
module.vpc.private_subnet_ids
```

### Path References

```hcl
path.module    # Path of the module where the expression is defined
path.root      # Path of the root module
path.cwd       # Path of the current working directory

# Common usage: referencing files relative to the module
resource "aws_lambda_function" "example" {
  filename = "${path.module}/lambda/handler.zip"
}
```

### Terraform Object References

```hcl
terraform.workspace    # Current workspace name
```

---

## JSON Compatibility

Every Terraform configuration written in HCL has an equivalent JSON representation. JSON files use the `.tf.json` extension.

### HCL

```hcl
resource "aws_instance" "example" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"

  tags = {
    Name = "example"
  }
}
```

### Equivalent JSON

```json
{
  "resource": {
    "aws_instance": {
      "example": {
        "ami": "ami-0abcdef1234567890",
        "instance_type": "t3.micro",
        "tags": {
          "Name": "example"
        }
      }
    }
  }
}
```

JSON format is useful for:

- Machine-generated configurations
- Integration with tools that output JSON
- Programmatic configuration generation

For hand-written configurations, HCL is always preferred for readability.

---

## Best Practices

### Naming Conventions

```hcl
# Use snake_case for all identifiers
resource "aws_instance" "web_server" {}      # correct
resource "aws_instance" "webServer" {}       # avoid camelCase
resource "aws_instance" "web-server" {}      # avoid kebab-case

# Use descriptive, meaningful names
resource "aws_security_group" "allow_https" {}  # good
resource "aws_security_group" "sg1" {}          # bad
```

### Formatting

```hcl
# Always run terraform fmt before committing
# Align equals signs within a block for readability
resource "aws_instance" "web" {
  ami           = "ami-0abcdef1234567890"
  instance_type = "t3.micro"
  key_name      = "deployer"

  tags = {
    Name        = "web-server"
    Environment = "production"
  }
}
```

### Type Constraints

Always declare explicit types for variables:

```hcl
# Good: explicit type
variable "instance_count" {
  type    = number
  default = 1
}

# Avoid: no type constraint (accepts anything)
variable "instance_count" {
  default = 1
}
```

### Ordering Within Blocks

Follow a consistent argument ordering:

1. Meta-arguments (`count`, `for_each`, `depends_on`, `provider`, `lifecycle`)
2. Required arguments
3. Optional arguments
4. Nested blocks (e.g., `tags`, `ingress`, `egress`)

```hcl
resource "aws_instance" "web" {
  count = var.instance_count              # meta-argument first

  ami           = var.ami_id              # required arguments
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  key_name   = var.key_name              # optional arguments
  monitoring = true

  root_block_device {                     # nested blocks
    volume_size = 50
    volume_type = "gp3"
  }

  tags = local.common_tags               # tags last

  lifecycle {                             # lifecycle last
    create_before_destroy = true
  }
}
```

### File Organization

- One resource type per file is too granular for most projects.
- Group related resources together (e.g., all networking in `networking.tf`, all IAM in `iam.tf`).
- Keep `variables.tf` and `outputs.tf` as separate files even if small.
- Use `locals.tf` for complex computed values to keep other files clean.

---

## Next Steps

- [Terraform CLI Commands](terraform-cli-commands.md) to see how these configurations are applied
- [Variables and Outputs](../02-terraform-intermediate/variables-and-outputs.md) for deeper coverage of variables
- [Functions and Expressions](../02-terraform-intermediate/functions-and-expressions.md) for HCL's built-in functions
