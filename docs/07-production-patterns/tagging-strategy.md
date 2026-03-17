# Tagging Strategy

## Overview

Tags are the foundation of cost allocation, access control, automation, and compliance in AWS. Without a consistent tagging strategy, you cannot attribute costs, enforce policies, or automate operations. This guide covers tag schema design, enforcement mechanisms, and automation patterns.

---

## Tag Schema

### Required Tags

Every AWS resource must have these tags:

| Tag Key | Description | Example Values | Purpose |
|---------|-------------|----------------|---------|
| `Environment` | Deployment environment | production, staging, development | Cost allocation, access control |
| `Team` | Owning team | platform, backend, data, frontend | Cost attribution, ownership |
| `Project` | Project or product name | checkout-api, data-pipeline | Cost allocation, grouping |
| `CostCenter` | Finance cost center | CC-1234, ENG-5678 | Financial reporting |
| `ManagedBy` | How the resource is managed | terraform, manual, cdk, cloudformation | Drift detection, governance |
| `Owner` | Contact for the resource | platform@example.com | Incident response |

### Optional Tags

| Tag Key | Description | When to Use |
|---------|-------------|-------------|
| `Application` | Application name | Multi-app environments |
| `DataClassification` | Data sensitivity | compliance (public, internal, confidential, restricted) |
| `Backup` | Backup schedule | Resources needing scheduled backups |
| `ExpiresAt` | Auto-delete date | Temporary/sandbox resources |
| `Compliance` | Compliance framework | Regulated workloads (pci-dss, hipaa, sox) |

### Automation Tags

| Tag Key | Description | Used By |
|---------|-------------|---------|
| `kubernetes.io/cluster/<name>` | EKS cluster membership | EKS, ALB Controller |
| `karpenter.sh/discovery` | Karpenter node discovery | Karpenter |
| `aws:autoscaling:groupName` | ASG membership | Auto Scaling |
| `Snapshot` | Snapshot schedule | DLM lifecycle policies |

---

## Implementation with Terraform

### Default Tags (Provider Level)

```hcl
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Team        = var.team
      Project     = var.project
      CostCenter  = var.cost_center
      ManagedBy   = "terraform"
      Owner       = var.owner_email
    }
  }
}
```

Default tags apply to every resource created by this provider. Resource-level tags merge with (and can override) default tags.

### Resource-Specific Tags

```hcl
resource "aws_instance" "app" {
  # ...

  tags = {
    Name        = "${var.environment}-app-server"
    Application = "checkout-api"
    Backup      = "daily"
  }
}
```

### Tag Validation

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["production", "staging", "development", "sandbox"], var.environment)
    error_message = "Environment must be one of: production, staging, development, sandbox."
  }
}

variable "team" {
  type = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]+$", var.team))
    error_message = "Team must be lowercase alphanumeric with hyphens."
  }
}
```

---

## Tag Enforcement

### AWS Config Rules

```hcl
resource "aws_config_config_rule" "required_tags" {
  name = "required-tags"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    tag1Key   = "Environment"
    tag1Value = "production,staging,development,sandbox"
    tag2Key   = "Team"
    tag3Key   = "Project"
    tag4Key   = "CostCenter"
    tag5Key   = "ManagedBy"
    tag6Key   = "Owner"
  })

  scope {
    compliance_resource_types = [
      "AWS::EC2::Instance",
      "AWS::EC2::Volume",
      "AWS::EC2::SecurityGroup",
      "AWS::RDS::DBInstance",
      "AWS::S3::Bucket",
      "AWS::Lambda::Function",
      "AWS::ECS::Service",
      "AWS::ElastiCache::CacheCluster",
      "AWS::EKS::Cluster",
    ]
  }
}

# Auto-remediation — tag non-compliant resources
resource "aws_config_remediation_configuration" "tag_remediation" {
  config_rule_name = aws_config_config_rule.required_tags.name
  target_type      = "SSM_DOCUMENT"
  target_id        = "AWS-SetRequiredTags"

  parameter {
    name         = "RequiredTags"
    static_value = jsonencode({ ManagedBy = "unknown" })
  }

  automatic                  = true
  maximum_automatic_attempts = 3
  retry_attempt_seconds      = 60
}
```

### Service Control Policy (SCP)

```hcl
resource "aws_organizations_policy" "require_tags" {
  name = "require-tags-on-create"
  type = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "RequireTagsOnCreate"
      Effect = "Deny"
      Action = [
        "ec2:RunInstances",
        "rds:CreateDBInstance",
        "s3:CreateBucket",
        "lambda:CreateFunction",
        "ecs:CreateService",
      ]
      Resource = "*"
      Condition = {
        "Null" = {
          "aws:RequestTag/Environment" = "true"
          "aws:RequestTag/Team"        = "true"
        }
      }
    }]
  })
}
```

### Checkov Checks

```yaml
# .checkov.yml
checks:
  - CKV_AWS_153  # Ensure that resources have tags
```

---

## Cost Allocation Tags

### Activation

```hcl
resource "aws_ce_cost_allocation_tag" "tags" {
  for_each = toset([
    "Environment",
    "Team",
    "Project",
    "CostCenter",
    "Application",
  ])

  tag_key = each.value
  status  = "Active"
}
```

### Cost Categories

```hcl
resource "aws_ce_cost_category" "team" {
  name = "Team"

  rule {
    value = "Platform"
    rule {
      tags {
        key           = "Team"
        values        = ["platform"]
        match_options = ["EQUALS"]
      }
    }
  }

  rule {
    value = "Backend"
    rule {
      tags {
        key           = "Team"
        values        = ["backend"]
        match_options = ["EQUALS"]
      }
    }
  }

  rule {
    value = "Data"
    rule {
      tags {
        key           = "Team"
        values        = ["data"]
        match_options = ["EQUALS"]
      }
    }
  }

  default_value = "Untagged"
}
```

---

## Tag-Based Resource Groups

```hcl
resource "aws_resourcegroups_group" "production" {
  name = "production-resources"

  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [{
        Key    = "Environment"
        Values = ["production"]
      }]
    })
  }

  tags = {
    Purpose = "resource-grouping"
  }
}
```

---

## Tag Naming Conventions

| Convention | Example | Notes |
|-----------|---------|-------|
| PascalCase | `Environment`, `CostCenter` | AWS standard, recommended |
| Prefix namespacing | `myorg:Environment` | Avoids conflicts with AWS tags |
| Lowercase | `environment`, `team` | Common in Terraform community |
| AWS-reserved | `aws:*` | Never use this prefix |

**Recommendation**: Use PascalCase without prefixes for simplicity and AWS console compatibility.

---

## Best Practices

1. **Use `default_tags`** in the AWS provider — ensures every resource gets required tags.
2. **Enforce tags with SCPs** — prevent resource creation without required tags.
3. **Activate cost allocation tags** — tags do not appear in Cost Explorer until activated.
4. **Audit tag compliance monthly** — use AWS Config for continuous monitoring.
5. **Keep tag values consistent** — "production" not "prod", "Production", or "PRODUCTION".
6. **Use validation blocks** in variables — catch bad values at plan time.
7. **Tag resources not supported by default_tags** manually — some resource types need explicit tags.
8. **Review untagged resources** — they represent blind spots in cost allocation.

---

## Related Guides

- [Cost Management](../04-aws-services-guide/cost-management.md) — Cost allocation with tags
- [Compliance](compliance-and-governance.md) — AWS Config enforcement
- [Multi-Environment](multi-environment.md) — Environment-based tagging
