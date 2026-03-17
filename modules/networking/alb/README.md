# ALB Module

Production-grade AWS Application Load Balancer module with HTTP/HTTPS listeners, target groups, and access logging.

## Features

- Application Load Balancer (internal or internet-facing)
- HTTP listener with configurable default action (forward, redirect, fixed-response)
- Optional HTTPS listener with TLS 1.3 policy
- Default target group with health checks and stickiness
- Access logs to S3
- Deletion protection toggle
- HTTP/2 support
- Invalid header field dropping

## Usage

```hcl
module "alb" {
  source = "../../modules/networking/alb"

  project     = "myapp"
  environment = "prod"
  vpc_id      = module.vpc.vpc_id
  subnet_ids  = module.vpc.public_subnet_ids

  security_group_ids = [module.alb_sg.security_group_id]

  enable_https_listener = true
  ssl_certificate_arn   = module.acm.certificate_arn

  http_default_action_type = "redirect"

  health_check = {
    path    = "/health"
    matcher = "200"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project name | string | - | yes |
| environment | Environment name | string | - | yes |
| vpc_id | VPC ID | string | - | yes |
| subnet_ids | Subnet IDs (min 2) | list(string) | - | yes |
| security_group_ids | Security group IDs | list(string) | - | yes |
| enable_https_listener | Create HTTPS listener | bool | false | no |
| ssl_certificate_arn | ACM certificate ARN | string | "" | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_arn | ALB ARN |
| alb_dns_name | ALB DNS name |
| alb_zone_id | ALB zone ID (for Route53) |
| target_group_arn | Default target group ARN |
