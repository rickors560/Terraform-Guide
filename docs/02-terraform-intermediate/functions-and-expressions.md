# Functions and Expressions

## Table of Contents

- [Overview](#overview)
- [String Functions](#string-functions)
- [Numeric Functions](#numeric-functions)
- [Collection Functions](#collection-functions)
- [Encoding Functions](#encoding-functions)
- [Filesystem Functions](#filesystem-functions)
- [Date and Time Functions](#date-and-time-functions)
- [Hash and Crypto Functions](#hash-and-crypto-functions)
- [IP Network Functions](#ip-network-functions)
- [Type Conversion Functions](#type-conversion-functions)
- [Conditional Expressions](#conditional-expressions)
- [For Expressions](#for-expressions)
- [Dynamic Blocks](#dynamic-blocks)
- [Splat Expressions](#splat-expressions)

---

## Overview

Terraform includes a set of built-in functions that you can call from within expressions to transform and combine values. Functions are called with the syntax `function_name(arg1, arg2, ...)`.

Test functions interactively with `terraform console`:

```bash
$ terraform console
> upper("hello")
"HELLO"
> max(5, 12, 9)
12
> cidrsubnet("10.0.0.0/16", 8, 1)
"10.0.1.0/24"
```

Terraform does not support user-defined functions. All available functions are built-in.

---

## String Functions

### format / formatlist

```hcl
# format — sprintf-style formatting
format("Hello, %s! You have %d messages.", "Alice", 5)
# "Hello, Alice! You have 5 messages."

format("%-20s %s", "Name:", "web-server")
# "Name:                web-server"

# formatlist — applies format to each element
formatlist("instance-%s", ["a", "b", "c"])
# ["instance-a", "instance-b", "instance-c"]
```

### join / split

```hcl
join(", ", ["a", "b", "c"])
# "a, b, c"

join("-", ["web", "server", "01"])
# "web-server-01"

split(",", "a,b,c")
# ["a", "b", "c"]
```

### upper / lower / title

```hcl
upper("hello")     # "HELLO"
lower("HELLO")     # "hello"
title("hello world")  # "Hello World"
```

### trimspace / trim / trimprefix / trimsuffix

```hcl
trimspace("  hello  ")          # "hello"
trim("?!hello?!", "?!")         # "hello"
trimprefix("helloworld", "hello")  # "world"
trimsuffix("helloworld", "world")  # "hello"
```

### replace

```hcl
replace("hello world", " ", "-")        # "hello-world"
replace("aabbcc", "/a+/", "x")          # "xbbcc" (regex with /.../)
```

### regex / regexall

```hcl
regex("^([a-z]+)-([0-9]+)$", "web-42")
# ["web", "42"]

regexall("[a-z]+", "abc 123 def 456")
# ["abc", "def"]

# Check if a string matches a pattern
can(regex("^[a-z]+$", var.name))   # returns true/false
```

### substr

```hcl
substr("hello world", 0, 5)   # "hello"
substr("hello world", 6, -1)  # "world" (-1 means to end)
```

### startswith / endswith (Terraform 1.3+)

```hcl
startswith("hello world", "hello")  # true
endswith("hello world", "world")    # true
```

### templatefile

Renders a template file with variables:

```hcl
# templates/user_data.sh
templatefile("${path.module}/templates/user_data.sh", {
  db_host     = aws_db_instance.main.endpoint
  app_version = var.app_version
  ports       = [80, 443]
})
```

Template file (`templates/user_data.sh`):

```bash
#!/bin/bash
echo "Connecting to ${db_host}"
echo "Deploying version ${app_version}"
%{ for port in ports ~}
ufw allow ${port}
%{ endfor ~}
```

---

## Numeric Functions

```hcl
abs(-42)              # 42
ceil(4.3)             # 5
floor(4.7)            # 4
max(5, 12, 9)         # 12
min(5, 12, 9)         # 5
pow(2, 10)            # 1024
signum(-5)            # -1  (returns -1, 0, or 1)
parseint("FF", 16)    # 255
log(100, 10)          # 2
```

### Practical Examples

```hcl
locals {
  # Calculate number of subnets from CIDR
  subnet_bits     = 8
  total_subnets   = pow(2, local.subnet_bits)   # 256
  subnets_per_az  = floor(local.total_subnets / length(var.azs))

  # Round up instance count to nearest even number
  raw_count    = var.desired_count
  even_count   = ceil(local.raw_count / 2) * 2
}
```

---

## Collection Functions

### length

```hcl
length(["a", "b", "c"])         # 3
length("hello")                  # 5
length({ a = 1, b = 2 })       # 2
```

### element / index

```hcl
element(["a", "b", "c"], 1)     # "b"
element(["a", "b", "c"], 5)     # "c" (wraps around: 5 % 3 = 2)
index(["a", "b", "c"], "b")     # 1
```

### lookup

```hcl
lookup({ a = 1, b = 2 }, "a", 0)   # 1
lookup({ a = 1, b = 2 }, "c", 0)   # 0 (default)
```

### merge / keys / values

```hcl
merge({ a = 1 }, { b = 2 }, { a = 3 })
# { a = 3, b = 2 }  (later values override)

keys({ a = 1, b = 2 })      # ["a", "b"]
values({ a = 1, b = 2 })    # [1, 2]
```

### flatten

```hcl
flatten([["a", "b"], ["c"], ["d", "e"]])
# ["a", "b", "c", "d", "e"]

# Common pattern: flatten nested for_each structures
locals {
  all_rules = flatten([
    for sg_name, sg in var.security_groups : [
      for rule in sg.rules : {
        sg_name   = sg_name
        port      = rule.port
        cidr      = rule.cidr
      }
    ]
  ])
}
```

### concat / distinct / sort / reverse

```hcl
concat(["a", "b"], ["c", "d"])     # ["a", "b", "c", "d"]
distinct(["a", "b", "a", "c"])     # ["a", "b", "c"]
sort(["c", "a", "b"])              # ["a", "b", "c"]
reverse(["a", "b", "c"])           # ["c", "b", "a"]
```

### contains

```hcl
contains(["a", "b", "c"], "b")     # true
contains(["a", "b", "c"], "d")     # false
```

### coalesce / coalescelist

```hcl
coalesce("", "", "hello", "world")     # "hello" (first non-empty)
coalesce(null, null, "fallback")       # "fallback"

coalescelist([], [], ["a", "b"])       # ["a", "b"] (first non-empty list)
```

### range

```hcl
range(3)           # [0, 1, 2]
range(1, 4)        # [1, 2, 3]
range(0, 10, 2)    # [0, 2, 4, 6, 8]
```

### zipmap

```hcl
zipmap(["name", "age"], ["Alice", "30"])
# { name = "Alice", age = "30" }

# Practical: create a map from instance IDs to IPs
zipmap(
  aws_instance.web[*].id,
  aws_instance.web[*].private_ip
)
```

### one

```hcl
one([])           # null
one(["a"])        # "a"
one(["a", "b"])   # Error: must be 0 or 1 elements

# Useful with conditional resources
one(aws_instance.bastion[*].public_ip)
```

### setproduct / setunion / setintersection / setsubtract

```hcl
setproduct(["web", "api"], ["dev", "prod"])
# [["web", "dev"], ["web", "prod"], ["api", "dev"], ["api", "prod"]]

setunion(["a", "b"], ["b", "c"])           # ["a", "b", "c"]
setintersection(["a", "b"], ["b", "c"])    # ["b"]
setsubtract(["a", "b", "c"], ["b"])        # ["a", "c"]
```

---

## Encoding Functions

### jsonencode / jsondecode

```hcl
jsonencode({ name = "web", port = 80 })
# "{\"name\":\"web\",\"port\":80}"

jsondecode("{\"name\":\"web\",\"port\":80}")
# { name = "web", port = 80 }

# Common: IAM policy in Terraform
resource "aws_iam_policy" "example" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject"]
      Resource = ["arn:aws:s3:::my-bucket/*"]
    }]
  })
}
```

### yamlencode / yamldecode

```hcl
yamlencode({ name = "web", ports = [80, 443] })
# "name: web\nports:\n- 80\n- 443\n"

yamldecode(file("config.yaml"))
```

### base64encode / base64decode

```hcl
base64encode("hello world")
# "aGVsbG8gd29ybGQ="

base64decode("aGVsbG8gd29ybGQ=")
# "hello world"

# Common: user_data for launch templates
resource "aws_launch_template" "web" {
  user_data = base64encode(templatefile("user_data.sh", { ... }))
}
```

### urlencode

```hcl
urlencode("hello world!")
# "hello+world%21"
```

### csvdecode

```hcl
csvdecode("name,age\nAlice,30\nBob,25")
# [{ name = "Alice", age = "30" }, { name = "Bob", age = "25" }]

# Read a CSV file
locals {
  servers = csvdecode(file("${path.module}/servers.csv"))
}
```

---

## Filesystem Functions

```hcl
# Read a file as a string
file("${path.module}/scripts/setup.sh")

# Check if a file exists
fileexists("${path.module}/optional-config.json")

# Read a file and base64-encode it
filebase64("${path.module}/binary-data.bin")

# Read a file set (glob pattern)
fileset(path.module, "templates/*.tpl")
# ["templates/app.tpl", "templates/nginx.tpl"]

# Template from file
templatefile("${path.module}/templates/config.tpl", {
  server_name = "web-01"
  port        = 8080
})

# Get directory name and base name
dirname("/foo/bar/baz.txt")    # "/foo/bar"
basename("/foo/bar/baz.txt")   # "baz.txt"

# Get absolute path
abspath("relative/path")

# File hash (for change detection)
filemd5("${path.module}/lambda.zip")
filesha256("${path.module}/lambda.zip")
filesha512("${path.module}/lambda.zip")
```

### Practical: Lambda Deployment

```hcl
resource "aws_lambda_function" "api" {
  filename         = "${path.module}/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")
  function_name    = "api-handler"
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  role             = aws_iam_role.lambda.arn
}
```

---

## Date and Time Functions

```hcl
# Current timestamp (evaluated at plan time, not apply time)
timestamp()
# "2024-01-15T10:30:00Z"

# Format a timestamp
formatdate("YYYY-MM-DD", timestamp())
# "2024-01-15"

formatdate("DD MMM YYYY hh:mm ZZZ", "2024-01-15T10:30:00Z")
# "15 Jan 2024 10:30 UTC"

# Add time to a timestamp
timeadd("2024-01-15T10:00:00Z", "24h")
# "2024-01-16T10:00:00Z"

timeadd(timestamp(), "720h")  # 30 days from now

# Compare timestamps
timecmp("2024-01-15T00:00:00Z", "2024-02-15T00:00:00Z")
# -1 (first is before second)
# Returns: -1, 0, or 1

# Practical: certificate expiration
resource "aws_acm_certificate" "main" {
  # ...
  lifecycle {
    create_before_destroy = true
  }
}

locals {
  cert_renewal_date = timeadd(timestamp(), "2160h")  # 90 days
}
```

---

## Hash and Crypto Functions

```hcl
md5("hello")
# "5d41402abc4b2a76b9719d911017c592"

sha1("hello")
sha256("hello")
sha512("hello")

# Base64 variants
base64sha256("hello")
base64sha512("hello")

# UUID generation
uuid()
# "e3b0c442-98fc-1c14-b39f-4c7e5e8e2f00"

# Bcrypt (for password hashing)
bcrypt("my-password")
bcrypt("my-password", 12)  # with cost factor

# Practical: unique resource naming
locals {
  unique_suffix = substr(md5("${var.project}-${var.environment}"), 0, 8)
  bucket_name   = "${var.project}-${var.environment}-${local.unique_suffix}"
}
```

---

## IP Network Functions

### cidrhost

Calculate a host IP within a CIDR block:

```hcl
cidrhost("10.0.0.0/24", 5)    # "10.0.0.5"
cidrhost("10.0.0.0/24", -1)   # "10.0.0.255" (broadcast)
```

### cidrnetmask

```hcl
cidrnetmask("10.0.0.0/16")    # "255.255.0.0"
cidrnetmask("10.0.0.0/24")    # "255.255.255.0"
```

### cidrsubnet

The most important networking function. Calculates a subnet CIDR within a parent CIDR:

```hcl
# cidrsubnet(prefix, newbits, netnum)
cidrsubnet("10.0.0.0/16", 8, 0)    # "10.0.0.0/24"
cidrsubnet("10.0.0.0/16", 8, 1)    # "10.0.1.0/24"
cidrsubnet("10.0.0.0/16", 8, 255)  # "10.0.255.0/24"
cidrsubnet("10.0.0.0/16", 4, 1)    # "10.0.16.0/20"
```

### Practical: VPC Subnet Calculation

```hcl
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "azs" {
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

locals {
  # /16 -> 8 new bits -> /24 subnets
  public_subnets  = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i + 100)]
  db_subnets      = [for i, az in var.azs : cidrsubnet(var.vpc_cidr, 8, i + 200)]
}

# Results:
# public_subnets  = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
# private_subnets = ["10.0.100.0/24", "10.0.101.0/24", "10.0.102.0/24"]
# db_subnets      = ["10.0.200.0/24", "10.0.201.0/24", "10.0.202.0/24"]
```

### cidrsubnets (Terraform 0.12.21+)

Calculate multiple subnets at once with different sizes:

```hcl
cidrsubnets("10.0.0.0/16", 8, 8, 8, 4)
# ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24", "10.0.16.0/20"]
```

---

## Type Conversion Functions

```hcl
tostring(42)                    # "42"
tonumber("42")                  # 42
tobool("true")                  # true

tolist(toset(["c", "a", "b"]))  # ["a", "b", "c"] (sorted by set)
toset(["a", "b", "a"])          # ["a", "b"] (deduplicated)
tomap({ a = 1, b = 2 })        # { a = 1, b = 2 }

# try — returns the first expression that doesn't produce an error
try(var.complex.nested.value, "default")

# can — returns whether an expression can be evaluated without error
can(regex("^[a-z]+$", var.name))   # true or false
```

### Practical: Safe Attribute Access

```hcl
locals {
  # Safely access optional nested attributes
  db_port = try(var.database_config.port, 5432)

  # Validate and provide defaults
  region = try(
    regex("^(us|eu|ap)-", var.region) != null ? var.region : null,
    "us-east-1"
  )
}
```

---

## Conditional Expressions

```hcl
# Syntax: condition ? true_value : false_value

locals {
  instance_type = var.environment == "prod" ? "t3.large" : "t3.micro"
  monitoring    = var.environment != "dev"
  az_count      = var.environment == "prod" ? 3 : 2
}

# Conditional resource creation with count
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
}

# Conditional with for_each
resource "aws_cloudwatch_metric_alarm" "cpu" {
  for_each = var.environment == "prod" ? toset(["high", "critical"]) : toset([])

  alarm_name = "cpu-${each.key}"
  # ...
}
```

---

## For Expressions

### List Generation

```hcl
# Transform a list
[for s in var.names : upper(s)]
# ["alice", "bob"] -> ["ALICE", "BOB"]

# Filter a list
[for s in var.names : s if length(s) > 3]
# ["alice", "bob", "charlie"] -> ["alice", "charlie"]

# Transform with index
[for i, s in var.names : "${i}: ${s}"]
# ["0: alice", "1: bob"]
```

### Map Generation

```hcl
# List to map
{ for s in var.names : s => upper(s) }
# { alice = "ALICE", bob = "BOB" }

# Map transformation
{ for k, v in var.tags : upper(k) => v }

# Group by (with ... suffix for collecting multiple values per key)
{ for s in var.servers : s.role => s.name... }
# { web = ["web-1", "web-2"], api = ["api-1"] }
```

### Practical Examples

```hcl
# Create a map of instance IDs to details
locals {
  instance_map = {
    for inst in aws_instance.web :
    inst.id => {
      az         = inst.availability_zone
      private_ip = inst.private_ip
      public_ip  = inst.public_ip
    }
  }
}

# Create subnet configuration from CIDR
locals {
  subnets = {
    for i, az in var.availability_zones :
    az => {
      public_cidr  = cidrsubnet(var.vpc_cidr, 8, i)
      private_cidr = cidrsubnet(var.vpc_cidr, 8, i + 100)
    }
  }
}

# Flatten nested structures for for_each
locals {
  sg_rules = flatten([
    for sg_name, sg in var.security_groups : [
      for rule in sg.ingress_rules : {
        key       = "${sg_name}-${rule.port}"
        sg_name   = sg_name
        port      = rule.port
        cidr      = rule.cidr
        protocol  = rule.protocol
      }
    ]
  ])

  sg_rules_map = { for rule in local.sg_rules : rule.key => rule }
}

resource "aws_security_group_rule" "ingress" {
  for_each = local.sg_rules_map

  type              = "ingress"
  from_port         = each.value.port
  to_port           = each.value.port
  protocol          = each.value.protocol
  cidr_blocks       = [each.value.cidr]
  security_group_id = aws_security_group.groups[each.value.sg_name].id
}
```

---

## Dynamic Blocks

Dynamic blocks generate repeated nested blocks within a resource:

```hcl
resource "aws_security_group" "web" {
  name   = "web-sg"
  vpc_id = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

### Variable Definition

```hcl
variable "ingress_rules" {
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))

  default = [
    {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    },
    {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    },
  ]
}
```

### Custom Iterator Name

```hcl
dynamic "setting" {
  for_each = var.settings
  iterator = s            # Use 's' instead of 'setting'

  content {
    namespace = s.value.namespace
    name      = s.value.name
    value     = s.value.value
  }
}
```

### Nested Dynamic Blocks

```hcl
dynamic "ingress" {
  for_each = var.ingress_rules
  content {
    from_port = ingress.value.port
    to_port   = ingress.value.port
    protocol  = ingress.value.protocol

    dynamic "security_groups" {
      for_each = ingress.value.security_group_ids
      content {
        security_group_id = security_groups.value
      }
    }
  }
}
```

**Warning**: Do not overuse dynamic blocks. They make configurations harder to read. Use them when the number of nested blocks genuinely varies. For a fixed set of blocks, write them out explicitly.

---

## Splat Expressions

Splat expressions are shorthand for extracting attributes from lists:

```hcl
# These are equivalent:
aws_instance.web[*].id
[for inst in aws_instance.web : inst.id]

# Nested attributes
aws_instance.web[*].ebs_block_device[*].volume_id

# With modules
module.servers[*].instance_id
```

### Legacy Splat (Attribute-only)

```hcl
# attribute.* syntax (legacy, only works with list-indexed resources)
aws_instance.web.*.id
```

The `[*]` syntax (full splat) is preferred over the legacy `.*` syntax.

---

## Next Steps

- [Data Sources](data-sources.md) for functions used with data source filtering
- [Variables and Outputs](variables-and-outputs.md) for variable validation with functions
- [HCL Syntax](../01-terraform-basics/hcl-syntax.md) for the language fundamentals these functions build upon
