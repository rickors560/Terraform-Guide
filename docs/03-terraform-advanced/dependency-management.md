# Dependency Management

## Table of Contents

- [How Terraform Manages Dependencies](#how-terraform-manages-dependencies)
- [The Dependency Graph](#the-dependency-graph)
- [Implicit Dependencies](#implicit-dependencies)
- [Explicit Dependencies with depends_on](#explicit-dependencies-with-depends_on)
- [Module Dependencies](#module-dependencies)
- [Data Source Ordering](#data-source-ordering)
- [Circular Dependency Resolution](#circular-dependency-resolution)
- [Resource Lifecycle and Dependencies](#resource-lifecycle-and-dependencies)
- [Cross-Configuration Dependencies](#cross-configuration-dependencies)
- [Debugging Dependencies](#debugging-dependencies)
- [Best Practices](#best-practices)

---

## How Terraform Manages Dependencies

Terraform builds a directed acyclic graph (DAG) of all resources and their dependencies. This graph determines:

1. **Creation order**: Which resources must be created first
2. **Destruction order**: Which resources must be destroyed last (reverse of creation)
3. **Parallelism**: Which resources can be created simultaneously
4. **Refresh order**: Which resources to read first during state refresh

Terraform resolves dependencies automatically in most cases by analyzing resource references. When automatic resolution is insufficient, you use `depends_on` to declare explicit dependencies.

---

## The Dependency Graph

### Viewing the Graph

```bash
# Generate DOT format
terraform graph

# Render to an image (requires Graphviz)
terraform graph | dot -Tpng > graph.png
terraform graph | dot -Tsvg > graph.svg

# Different graph types
terraform graph -type=plan       # What will change
terraform graph -type=apply      # Apply order
terraform graph -type=plan-refresh-only  # Refresh order
```

### Example Graph

For this configuration:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id
}

resource "aws_instance" "web" {
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.web.id]
}
```

The dependency graph is:

```
aws_vpc.main
  ├── aws_subnet.private
  │     └── aws_instance.web
  └── aws_security_group.web
        └── aws_instance.web
```

Creation order:
1. `aws_vpc.main` (no dependencies)
2. `aws_subnet.private` and `aws_security_group.web` (in parallel, both depend only on VPC)
3. `aws_instance.web` (depends on both subnet and security group)

Destruction order (reverse):
1. `aws_instance.web`
2. `aws_subnet.private` and `aws_security_group.web` (in parallel)
3. `aws_vpc.main`

---

## Implicit Dependencies

Terraform creates implicit dependencies whenever one resource references another through an attribute:

### Reference-Based Dependencies

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Implicit dependency: references aws_vpc.main.id
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id      # <-- creates dependency
  cidr_block = "10.0.1.0/24"
}
```

### Module Output Dependencies

```hcl
module "vpc" {
  source = "./modules/vpc"
}

# Implicit dependency: references module.vpc output
resource "aws_instance" "web" {
  subnet_id = module.vpc.private_subnet_ids[0]   # <-- creates dependency
}
```

### Local Value Dependencies

```hcl
locals {
  vpc_id = aws_vpc.main.id    # Depends on aws_vpc.main
}

resource "aws_subnet" "private" {
  vpc_id = local.vpc_id        # Transitively depends on aws_vpc.main
}
```

### Data Source Dependencies

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Implicit dependency: filter references aws_vpc.main.id
data "aws_subnets" "existing" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]   # <-- creates dependency
  }
}
```

---

## Explicit Dependencies with depends_on

Use `depends_on` when there is a dependency that Terraform cannot detect from resource references. This is rare but necessary in specific situations.

### Syntax

```hcl
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  depends_on = [
    aws_iam_role_policy.s3_access,
    aws_security_group_rule.allow_https,
  ]
}
```

### When depends_on is Necessary

#### 1. IAM Policy Propagation

IAM policies take time to propagate. A resource that uses an IAM role may fail if the role's policy is not yet effective:

```hcl
resource "aws_iam_role" "lambda" {
  name = "lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "api" {
  function_name = "api-handler"
  role          = aws_iam_role.lambda.arn
  # ...

  # Lambda might fail to invoke if the policy is not yet attached
  depends_on = [aws_iam_role_policy_attachment.lambda_basic]
}
```

#### 2. Side Effects Not Captured in References

```hcl
resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
}

resource "aws_s3_bucket_policy" "data" {
  bucket = aws_s3_bucket.data.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

# This resource needs the bucket policy to be in place,
# but it doesn't reference the policy resource directly
resource "aws_s3_bucket_notification" "data" {
  bucket = aws_s3_bucket.data.id
  # ...

  depends_on = [aws_s3_bucket_policy.data]
}
```

#### 3. External System Dependencies

```hcl
resource "aws_route53_record" "cert_validation" {
  # ...
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]
}

# CloudFront needs the certificate to be validated first
resource "aws_cloudfront_distribution" "cdn" {
  # The certificate ARN is referenced, but validation is a separate concern
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.main.arn
  }

  depends_on = [aws_acm_certificate_validation.cert]
}
```

### depends_on with Modules

```hcl
module "iam" {
  source = "./modules/iam"
}

module "compute" {
  source = "./modules/compute"

  role_arn = module.iam.role_arn

  # Ensure all IAM resources are created before compute
  depends_on = [module.iam]
}
```

**Warning**: `depends_on` on a module creates a dependency on ALL resources in that module, not just the output. This can slow down plans and applies unnecessarily. Prefer implicit dependencies through output references when possible.

---

## Module Dependencies

### Output-Based Dependencies

The cleanest way to create inter-module dependencies:

```hcl
module "vpc" {
  source = "./modules/vpc"
}

module "database" {
  source = "./modules/database"

  # These references create implicit dependencies
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.database_subnet_ids
}

module "compute" {
  source = "./modules/compute"

  # Depends on both VPC and database modules
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.private_subnet_ids
  db_endpoint   = module.database.endpoint
}
```

Dependency order:
1. `module.vpc` (no dependencies)
2. `module.database` (depends on vpc)
3. `module.compute` (depends on vpc and database)

### Cross-Module Resource References

Within a module, you cannot directly reference resources from another module. You must pass values through outputs and variables:

```hcl
# modules/vpc/outputs.tf
output "vpc_id" {
  value = aws_vpc.main.id
}

# modules/compute/variables.tf
variable "vpc_id" {
  type = string
}

# Root module
module "vpc" { source = "./modules/vpc" }
module "compute" {
  source = "./modules/compute"
  vpc_id = module.vpc.vpc_id    # This creates the dependency chain
}
```

---

## Data Source Ordering

### Data Sources That Depend on Resources

When a data source depends on a resource being created in the same configuration, Terraform defers reading the data source until the apply phase:

```hcl
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# This data source cannot be read during plan because the VPC doesn't exist yet
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]    # Value unknown until apply
  }
}

# During plan, this shows "(known after apply)"
resource "aws_instance" "web" {
  subnet_id = data.aws_subnets.private.ids[0]
}
```

### Data Sources with Explicit Dependencies

```hcl
resource "aws_iam_role" "app" {
  name = "app-role"
  # ...
}

resource "aws_iam_role_policy" "app" {
  role   = aws_iam_role.app.id
  policy = "..."
}

# Read the role only after the policy is attached
data "aws_iam_role" "app" {
  name = aws_iam_role.app.name

  depends_on = [aws_iam_role_policy.app]
}
```

---

## Circular Dependency Resolution

Terraform does not allow circular dependencies. If resource A depends on resource B, and B depends on A, Terraform fails:

```
Error: Cycle: aws_security_group.a, aws_security_group.b
```

### Common Circular Dependency Patterns

#### Security Group Cross-References

```hcl
# CIRCULAR DEPENDENCY — this will fail
resource "aws_security_group" "app" {
  ingress {
    from_port       = 8080
    to_port         = 8080
    security_groups = [aws_security_group.db.id]    # depends on db
  }
}

resource "aws_security_group" "db" {
  ingress {
    from_port       = 5432
    to_port         = 5432
    security_groups = [aws_security_group.app.id]   # depends on app
  }
}
```

#### Solution: Separate Rule Resources

```hcl
resource "aws_security_group" "app" {
  name   = "app-sg"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group" "db" {
  name   = "db-sg"
  vpc_id = aws_vpc.main.id
}

# Rules are separate resources — no cycle
resource "aws_security_group_rule" "app_from_db" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db.id
  security_group_id        = aws_security_group.app.id
}

resource "aws_security_group_rule" "db_from_app" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.app.id
  security_group_id        = aws_security_group.db.id
}
```

#### Route53 and ACM Circular Dependency

```hcl
# POTENTIAL CYCLE: certificate needs DNS, DNS hosted zone needs to exist

# Solution: create the zone first, then the certificate
resource "aws_route53_zone" "main" {
  name = "example.com"
}

resource "aws_acm_certificate" "main" {
  domain_name       = "example.com"
  validation_method = "DNS"
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}
```

### General Strategies for Breaking Cycles

1. **Extract inline blocks into separate resources**: Security group rules, IAM policies, route table routes
2. **Use intermediate resources**: Create a `null_resource` or `terraform_data` as a synchronization point
3. **Split into separate configurations**: If two components are truly circular, manage them in separate Terraform states
4. **Restructure the design**: The circular dependency may indicate a design problem

---

## Resource Lifecycle and Dependencies

### create_before_destroy

When `create_before_destroy` is set, Terraform creates the replacement before destroying the old resource. Dependencies must also support this order:

```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"

  lifecycle {
    create_before_destroy = true
  }
}
```

If resource B depends on resource A, and A has `create_before_destroy`, Terraform:
1. Creates the new A
2. Updates B to reference the new A
3. Destroys the old A

### replace_triggered_by

Force a resource to be replaced when a dependency changes:

```hcl
resource "aws_instance" "web" {
  ami           = var.ami_id
  instance_type = "t3.micro"

  lifecycle {
    replace_triggered_by = [
      aws_security_group.web.id,      # Replace instance when SG changes
      null_resource.config_change.id,  # Replace on config change
    ]
  }
}
```

### prevent_destroy with Dependencies

If a resource has `prevent_destroy = true`, any dependent resource that would cause its destruction is also blocked:

```hcl
resource "aws_db_instance" "main" {
  # ...
  lifecycle {
    prevent_destroy = true
  }
}

# Changing this subnet group cannot force DB destruction
resource "aws_db_subnet_group" "main" {
  subnet_ids = var.subnet_ids
}
```

---

## Cross-Configuration Dependencies

When resources span multiple Terraform configurations (different state files), use these patterns:

### terraform_remote_state

```hcl
# Configuration A outputs the VPC ID
output "vpc_id" {
  value = aws_vpc.main.id
}

# Configuration B reads it
data "terraform_remote_state" "networking" {
  backend = "s3"
  config = {
    bucket = "terraform-state"
    key    = "networking/terraform.tfstate"
    region = "us-east-1"
  }
}

resource "aws_instance" "web" {
  subnet_id = data.terraform_remote_state.networking.outputs.private_subnet_ids[0]
}
```

### Native Data Sources (Preferred)

```hcl
# Look up the VPC directly instead of from state
data "aws_vpc" "main" {
  tags = { Name = "production" }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  tags = { Tier = "private" }
}
```

### SSM Parameter Store as a Dependency Bridge

Configuration A writes values to SSM:

```hcl
resource "aws_ssm_parameter" "vpc_id" {
  name  = "/infrastructure/vpc_id"
  type  = "String"
  value = aws_vpc.main.id
}
```

Configuration B reads them:

```hcl
data "aws_ssm_parameter" "vpc_id" {
  name = "/infrastructure/vpc_id"
}

resource "aws_instance" "web" {
  subnet_id = data.aws_ssm_parameter.vpc_id.value
}
```

---

## Debugging Dependencies

### View the Dependency Graph

```bash
terraform graph | dot -Tpng > deps.png
```

### Enable Debug Logging

```bash
export TF_LOG=DEBUG
terraform plan 2>&1 | grep -i "depend"
```

### Check Why a Resource is Planned

```bash
terraform plan -out=tfplan
terraform show -json tfplan | jq '.resource_changes[] | select(.address == "aws_instance.web")'
```

### Use terraform console to Inspect References

```bash
terraform console
> aws_vpc.main.id
> module.vpc.vpc_id
```

---

## Best Practices

### 1. Prefer Implicit Dependencies

Implicit dependencies (through resource references) are self-documenting, automatically maintained, and less error-prone. Only use `depends_on` when implicit dependencies are impossible.

### 2. Minimize depends_on Usage

`depends_on` creates a hard dependency that prevents parallel execution. Overuse slows down plans and applies.

### 3. Use Separate Rule Resources

Extract inline blocks (security group rules, IAM policies, route table routes) into separate resources to avoid circular dependencies and enable more granular dependency management.

### 4. Design Modules with Clear Interfaces

Modules should expose necessary values through outputs. This naturally creates the right dependency graph:

```hcl
# Good: dependency flows through outputs
module "vpc" { ... }
module "compute" {
  vpc_id = module.vpc.vpc_id    # Clear dependency
}

# Avoid: hidden dependency via depends_on
module "compute" {
  depends_on = [module.vpc]     # Opaque — why does it depend?
}
```

### 5. Avoid Overly Complex Dependency Chains

If your dependency graph is too complex to understand, your configuration may need to be split into smaller, independent configurations.

### 6. Test Dependency Order

Destroy and recreate to verify the dependency order is correct:

```bash
terraform destroy -auto-approve
terraform apply -auto-approve
```

If both succeed without errors, your dependencies are correct.

---

## Next Steps

- [Performance Optimization](performance-optimization.md) for parallelism and dependency-aware optimization
- [Modules](../02-terraform-intermediate/modules.md) for module dependency patterns
- [State Management](../01-terraform-basics/state-management.md) for state-level dependency tracking
