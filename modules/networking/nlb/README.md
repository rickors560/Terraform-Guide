# NLB Module

Production-grade AWS Network Load Balancer module with TCP/TLS listeners and target groups.

## Features

- Network Load Balancer (internal or internet-facing)
- Multiple TCP/TLS listeners
- Multiple target groups with health checks
- Cross-zone load balancing toggle
- TLS termination with certificate support
- Proxy Protocol v2 support
- Deletion protection toggle

## Usage

```hcl
module "nlb" {
  source = "../../modules/networking/nlb"

  project     = "myapp"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.private_subnet_ids

  internal                        = true
  enable_cross_zone_load_balancing = true

  target_groups = [
    {
      name     = "grpc"
      port     = 50051
      protocol = "TCP"
    },
  ]

  listeners = [
    {
      port               = 50051
      protocol           = "TCP"
      target_group_index = 0
    },
  ]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| vpc_id | VPC ID | string | - | yes |
| subnet_ids | Subnet IDs | list(string) | - | yes |
| listeners | Listener configs | list(object) | - | yes |
| target_groups | Target group configs | list(object) | - | yes |

## Outputs

| Name | Description |
|------|-------------|
| nlb_arn | NLB ARN |
| nlb_dns_name | NLB DNS name |
| target_group_arns | Target group ARNs |
| listener_arns | Listener ARNs |
