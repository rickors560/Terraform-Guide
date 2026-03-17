# VPC Module

Production-grade AWS VPC module with public, private, and database subnets across configurable availability zones.

## Features

- VPC with configurable CIDR block and DNS settings
- Public, private, and database subnet tiers using `cidrsubnet`
- Internet Gateway for public subnets
- NAT Gateways (single or one-per-AZ) for private subnets
- VPC Flow Logs to CloudWatch Logs
- Default security group locked down (deny all)
- Optional VPN Gateway
- Optional RDS database subnet group
- Consistent tagging on all resources

## Usage

```hcl
module "vpc" {
  source = "../../modules/networking/vpc"

  project     = "myapp"
  environment = "prod"
  vpc_cidr    = "10.0.0.0/16"

  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

  enable_nat_gateway = true
  single_nat_gateway = false
  enable_flow_logs   = true

  team        = "platform"
  cost_center = "engineering"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| vpc_cidr | VPC CIDR block | string | - | yes |
| availability_zones | List of AZs | list(string) | - | yes |
| enable_nat_gateway | Create NAT Gateways | bool | true | no |
| single_nat_gateway | Use single NAT GW | bool | false | no |
| enable_flow_logs | Enable VPC Flow Logs | bool | true | no |
| flow_log_retention_days | CW Logs retention | number | 30 | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | VPC ID |
| public_subnet_ids | Public subnet IDs |
| private_subnet_ids | Private subnet IDs |
| database_subnet_ids | Database subnet IDs |
| nat_gateway_ids | NAT Gateway IDs |
| nat_gateway_public_ips | NAT Gateway EIPs |
