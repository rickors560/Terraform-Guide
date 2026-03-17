# Security Groups Module

Flexible AWS Security Group module supporting ingress/egress rules with CIDR blocks, security group references, and self-referencing rules.

## Features

- Configurable ingress and egress rules as lists of objects
- Support for CIDR-based, security-group-based, and self-referencing rules
- create_before_destroy lifecycle for zero-downtime updates
- Revoke rules on delete for clean teardown
- Consistent naming and tagging

## Usage

```hcl
module "web_sg" {
  source = "../../modules/networking/security-groups"

  project     = "myapp"
  environment = "prod"
  name        = "web"
  description = "Security group for web servers"
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from anywhere"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from anywhere"
    },
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| name | Short name for the SG | string | - | yes |
| vpc_id | VPC ID | string | - | yes |
| ingress_rules | Ingress rules | list(object) | [] | no |
| egress_rules | Egress rules | list(object) | allow-all | no |

## Outputs

| Name | Description |
|------|-------------|
| security_group_id | Security Group ID |
| security_group_arn | Security Group ARN |
| security_group_name | Security Group name |
