# Variables and Outputs

## Table of Contents

- [Input Variables](#input-variables)
- [Variable Types](#variable-types)
- [Variable Defaults](#variable-defaults)
- [Variable Validation](#variable-validation)
- [Sensitive Variables](#sensitive-variables)
- [Variable Precedence](#variable-precedence)
- [Variable Files](#variable-files)
- [Output Values](#output-values)
- [Sensitive Outputs](#sensitive-outputs)
- [Output Dependencies](#output-dependencies)
- [Local Values](#local-values)
- [Best Practices](#best-practices)

---

## Input Variables

Input variables are the parameters of a Terraform module. They allow you to customize behavior without modifying the source code.

### Declaration

```hcl
variable "instance_type" {
  description = "The EC2 instance type for application servers"
  type        = string
  default     = "t3.micro"
}
```

### Full Variable Block

```hcl
variable "name" {
  description = "Human-readable explanation of what this variable controls"
  type        = string           # Type constraint
  default     = "value"          # Default value (makes variable optional)
  sensitive   = false            # Whether to redact from output
  nullable    = true             # Whether null is an acceptable value

  validation {
    condition     = length(var.name) > 0
    error_message = "Name must not be empty."
  }
}
```

### Using Variables

```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  tags = {
    Name        = "${var.project_name}-web"
    Environment = var.environment
  }
}
```

---

## Variable Types

### Primitive Types

```hcl
variable "name" {
  type = string
  default = "my-app"
}

variable "instance_count" {
  type = number
  default = 3
}

variable "enable_monitoring" {
  type = bool
  default = true
}
```

### Collection Types

```hcl
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "ingress_ports" {
  type    = list(number)
  default = [80, 443, 8080]
}

variable "instance_types" {
  type = map(string)
  default = {
    dev  = "t3.micro"
    prod = "t3.large"
  }
}

variable "unique_environments" {
  type    = set(string)
  default = ["dev", "staging", "prod"]
}
```

### Structural Types

```hcl
variable "database_config" {
  type = object({
    engine            = string
    engine_version    = string
    instance_class    = string
    allocated_storage = number
    multi_az          = bool
    backup_retention  = number
  })

  default = {
    engine            = "postgres"
    engine_version    = "15.4"
    instance_class    = "db.t3.medium"
    allocated_storage = 100
    multi_az          = true
    backup_retention  = 7
  }
}

variable "subnets" {
  type = list(object({
    cidr_block        = string
    availability_zone = string
    public            = bool
    tags              = map(string)
  }))
}
```

### Optional Object Attributes (Terraform 1.3+)

```hcl
variable "storage_config" {
  type = object({
    size_gb     = number
    type        = optional(string, "gp3")     # defaults to "gp3"
    iops        = optional(number)             # defaults to null
    throughput  = optional(number)             # defaults to null
    encrypted   = optional(bool, true)         # defaults to true
    kms_key_id  = optional(string)
  })
}

# Callers can omit optional fields
# storage_config = { size_gb = 100 }
# Results in: { size_gb = 100, type = "gp3", iops = null, throughput = null, encrypted = true, kms_key_id = null }
```

### Tuple Types

```hcl
variable "rule" {
  type    = tuple([string, number, string])
  default = ["allow", 443, "0.0.0.0/0"]
  # Access: var.rule[0] = "allow", var.rule[1] = 443, var.rule[2] = "0.0.0.0/0"
}
```

### The `any` Type

```hcl
variable "settings" {
  type = map(any)
  # Accepts any value type, but all values must be the same type
  # Terraform infers the actual type at runtime
}
```

---

## Variable Defaults

Variables without a `default` are required. Terraform will prompt for their value or fail if not provided:

```hcl
# Required variable (no default)
variable "environment" {
  description = "Deployment environment"
  type        = string
}

# Optional variable (has a default)
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

### Nullable Variables

By default, variables can accept `null` as a value, which falls back to the default:

```hcl
variable "key_name" {
  type     = string
  default  = "default-key"
  nullable = true     # null falls back to "default-key"
}

# With nullable = false, passing null is an error
variable "bucket_name" {
  type     = string
  nullable = false    # Must provide a non-null value
}
```

---

## Variable Validation

Custom validation rules enforce constraints beyond type checking:

### Basic Validation

```hcl
variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}
```

### Multiple Validation Rules

```hcl
variable "instance_type" {
  type = string

  validation {
    condition     = can(regex("^t3\\.", var.instance_type))
    error_message = "Instance type must be in the t3 family."
  }

  validation {
    condition     = !contains(["t3.nano"], var.instance_type)
    error_message = "t3.nano is not allowed for production workloads."
  }
}
```

### Common Validation Patterns

```hcl
# CIDR block validation
variable "vpc_cidr" {
  type = string

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
}

# AWS region validation
variable "region" {
  type = string

  validation {
    condition     = can(regex("^(us|eu|ap|sa|ca|me|af)-(north|south|east|west|central|northeast|southeast)-[1-3]$", var.region))
    error_message = "Must be a valid AWS region."
  }
}

# Email validation
variable "alert_email" {
  type = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.alert_email))
    error_message = "Must be a valid email address."
  }
}

# Port range validation
variable "app_port" {
  type = number

  validation {
    condition     = var.app_port >= 1024 && var.app_port <= 65535
    error_message = "Port must be between 1024 and 65535."
  }
}

# Length validation
variable "project_name" {
  type = string

  validation {
    condition     = length(var.project_name) >= 3 && length(var.project_name) <= 24
    error_message = "Project name must be between 3 and 24 characters."
  }

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.project_name))
    error_message = "Project name must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}
```

---

## Sensitive Variables

Mark variables as sensitive to prevent their values from appearing in CLI output and logs:

```hcl
variable "database_password" {
  description = "Password for the RDS database"
  type        = string
  sensitive   = true
}

variable "api_key" {
  description = "API key for the external service"
  type        = string
  sensitive   = true
}
```

### Behavior

```bash
# Plan output shows:
# + resource "aws_db_instance" "main" {
#     + password = (sensitive value)
#   }
```

**Important**: Sensitive variables are still stored in the state file in plain text. The `sensitive` flag only affects CLI output. Encrypt your state file and restrict access to it.

### Providing Sensitive Values

```bash
# Environment variable (recommended for CI/CD)
export TF_VAR_database_password="super-secret-password"

# Variable file (not committed to git)
# secrets.tfvars
database_password = "super-secret-password"

terraform apply -var-file="secrets.tfvars"

# Interactive prompt (when no default or value is provided)
# Terraform will prompt: var.database_password
```

---

## Variable Precedence

When the same variable is set in multiple places, Terraform uses this precedence (highest to lowest):

1. **`-var` and `-var-file` flags** on the command line (last one wins)
2. **`*.auto.tfvars`** or **`*.auto.tfvars.json`** files (alphabetical order)
3. **`terraform.tfvars`** or **`terraform.tfvars.json`** file
4. **Environment variables** (`TF_VAR_name`)
5. **Variable defaults** in the configuration
6. **Interactive prompt** (if no other source provides a value)

### Example

```hcl
# variables.tf
variable "instance_type" {
  default = "t3.micro"           # Priority 5
}
```

```hcl
# terraform.tfvars
instance_type = "t3.small"       # Priority 3
```

```hcl
# prod.auto.tfvars
instance_type = "t3.medium"      # Priority 2
```

```bash
export TF_VAR_instance_type="t3.large"    # Priority 4

terraform apply -var="instance_type=t3.xlarge"  # Priority 1 (WINS)
```

Result: `t3.xlarge` is used.

---

## Variable Files

### terraform.tfvars

Automatically loaded when present:

```hcl
# terraform.tfvars
environment    = "production"
instance_type  = "t3.large"
instance_count = 5

availability_zones = [
  "us-east-1a",
  "us-east-1b",
  "us-east-1c",
]

tags = {
  Project = "web-platform"
  Team    = "platform-engineering"
}
```

### Auto-loaded Files

Files matching `*.auto.tfvars` or `*.auto.tfvars.json` are automatically loaded in alphabetical order:

```
project/
  00-defaults.auto.tfvars
  01-environment.auto.tfvars
  main.tf
  variables.tf
```

### Named Variable Files

Load specific variable files with `-var-file`:

```bash
terraform plan -var-file="environments/prod.tfvars"
terraform apply -var-file="environments/prod.tfvars"
```

### JSON Variable Files

```json
{
  "environment": "production",
  "instance_type": "t3.large",
  "instance_count": 5,
  "availability_zones": ["us-east-1a", "us-east-1b"],
  "tags": {
    "Project": "web-platform"
  }
}
```

---

## Output Values

Outputs expose values from your module. They serve three purposes:

1. **Display information** after `terraform apply`
2. **Pass data** between modules
3. **Expose data** for external tools via `terraform output`

### Declaration

```hcl
output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "public_ip" {
  description = "The public IP address of the instance"
  value       = aws_instance.web.public_ip
}

output "load_balancer_url" {
  description = "URL of the application load balancer"
  value       = "https://${aws_lb.main.dns_name}"
}
```

### Complex Outputs

```hcl
output "instance_details" {
  description = "Map of instance IDs to their private IPs"
  value = {
    for inst in aws_instance.web :
    inst.id => {
      private_ip = inst.private_ip
      public_ip  = inst.public_ip
      az         = inst.availability_zone
    }
  }
}

output "subnet_ids" {
  description = "List of all private subnet IDs"
  value       = aws_subnet.private[*].id
}
```

### Conditional Outputs

```hcl
output "bastion_ip" {
  description = "Public IP of the bastion host (if created)"
  value       = var.create_bastion ? aws_instance.bastion[0].public_ip : null
}
```

### Accessing Outputs

```bash
# Show all outputs
terraform output

# Show a specific output
terraform output instance_id

# Raw value (no quotes) for use in scripts
terraform output -raw public_ip

# JSON format
terraform output -json

# Use in a script
IP=$(terraform output -raw public_ip)
ssh ec2-user@$IP
```

---

## Sensitive Outputs

Mark outputs as sensitive to prevent display in the console:

```hcl
output "database_connection_string" {
  description = "Database connection string"
  value       = "postgresql://${aws_db_instance.main.username}:${aws_db_instance.main.password}@${aws_db_instance.main.endpoint}/${aws_db_instance.main.db_name}"
  sensitive   = true
}

output "admin_password" {
  description = "Auto-generated admin password"
  value       = random_password.admin.result
  sensitive   = true
}
```

To view a sensitive output:

```bash
# This will show (sensitive value)
terraform output

# Use -json to see the actual value
terraform output -json admin_password

# Or use -raw
terraform output -raw admin_password
```

If a module output references a sensitive value and is not marked `sensitive`, Terraform raises an error. You must either mark the output as sensitive or use `nonsensitive()` to explicitly acknowledge you are exposing the value.

---

## Output Dependencies

Outputs can depend on resources that do not directly contribute to the output value. Use `depends_on` to express this:

```hcl
output "api_endpoint" {
  description = "The API gateway endpoint URL"
  value       = aws_api_gateway_deployment.main.invoke_url

  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_lambda_permission.api_gateway,
  ]
}
```

This ensures the output is not read until the dependent resources are fully created. This is primarily useful for `terraform_remote_state` consumers that depend on the completeness of the infrastructure.

### Preconditions and Postconditions (Terraform 1.2+)

```hcl
output "endpoint" {
  value = aws_lb.main.dns_name

  precondition {
    condition     = aws_lb.main.dns_name != ""
    error_message = "Load balancer DNS name is empty. Deployment may have failed."
  }
}
```

---

## Local Values

Local values are computed values within a module. They reduce repetition and improve readability:

```hcl
locals {
  # Common tags applied to all resources
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Owner       = var.team
  }

  # Computed name prefix
  name_prefix = "${var.project_name}-${var.environment}"

  # Conditional logic
  is_production = var.environment == "prod"
  instance_type = local.is_production ? "t3.large" : "t3.micro"

  # Complex computations
  subnet_cidrs = {
    for idx, az in var.availability_zones :
    az => cidrsubnet(var.vpc_cidr, 8, idx)
  }

  # Flattening nested structures
  security_group_rules = flatten([
    for group_name, rules in var.security_groups : [
      for rule in rules : {
        group_name = group_name
        port       = rule.port
        cidr       = rule.cidr
        protocol   = rule.protocol
      }
    ]
  ])
}
```

### Using Locals

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = local.instance_type

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-web"
    Role = "web-server"
  })
}

resource "aws_s3_bucket" "data" {
  bucket = "${local.name_prefix}-data"
  tags   = local.common_tags
}
```

### Locals vs Variables

| Aspect | Variables | Locals |
|--------|-----------|--------|
| Set by | Caller of the module | Computed within the module |
| Purpose | Parameterize the module | Simplify internal logic |
| Visibility | External (part of the API) | Internal only |
| Dynamic | Static value provided by user | Can reference other resources |

---

## Best Practices

### 1. Always Add Descriptions

```hcl
# Good
variable "retention_days" {
  description = "Number of days to retain CloudWatch logs before automatic deletion"
  type        = number
  default     = 30
}

# Bad
variable "retention_days" {
  type    = number
  default = 30
}
```

### 2. Use Specific Types

```hcl
# Good: explicit type
variable "port" {
  type = number
}

# Bad: no type (accepts anything)
variable "port" {}
```

### 3. Group Variables Logically

```hcl
# variables.tf — organized by purpose

# --- Networking ---
variable "vpc_cidr" { ... }
variable "subnet_cidrs" { ... }
variable "availability_zones" { ... }

# --- Compute ---
variable "instance_type" { ... }
variable "instance_count" { ... }
variable "ami_id" { ... }

# --- Database ---
variable "db_instance_class" { ... }
variable "db_storage_size" { ... }
variable "db_password" { ... }
```

### 4. Prefer Objects Over Many Separate Variables

```hcl
# Instead of:
variable "db_engine" {}
variable "db_version" {}
variable "db_instance_class" {}
variable "db_storage" {}

# Use:
variable "database" {
  type = object({
    engine         = string
    version        = string
    instance_class = string
    storage_gb     = number
  })
}
```

### 5. Never Put Secrets in Default Values

```hcl
# NEVER do this
variable "db_password" {
  default = "my-secret-password"   # This ends up in version control
}

# Do this instead
variable "db_password" {
  type      = string
  sensitive = true
  # No default — must be provided via TF_VAR, -var, or .tfvars
}
```

### 6. Use terraform.tfvars for Environment-Specific Values

```bash
# Directory structure
environments/
  dev.tfvars
  staging.tfvars
  prod.tfvars

# Usage
terraform plan -var-file="environments/prod.tfvars"
```

### 7. Use Locals for Computed Values

If a value is derived from other variables or resources, use `locals` instead of asking callers to compute it.

### 8. Output Everything Module Consumers Need

When writing a module, export all attributes that other modules or the root configuration might need. It is much easier to add outputs upfront than to release a new version later.

---

## Next Steps

- [Functions and Expressions](functions-and-expressions.md) for transforming variable values
- [Modules](modules.md) for using variables in modules
- [Data Sources](data-sources.md) for reading external data into variables
