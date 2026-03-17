# ALB Component

Production-grade Application Load Balancer with HTTP/HTTPS listeners, target group, access logs, and CloudWatch alarms.

## Features

- HTTP listener with automatic HTTPS redirect (when certificate provided)
- HTTPS listener with TLS 1.3 security policy
- Target group with configurable health checks and stickiness
- S3 access logs with lifecycle management
- CloudWatch alarms for 5XX errors, unhealthy hosts, and response time
- Drop invalid header fields for security

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vpc_id` | VPC ID | `string` | -- |
| `subnet_ids` | Subnet IDs (2+ AZs) | `list(string)` | -- |
| `acm_certificate_arn` | ACM cert ARN | `string` | `""` |
| `health_check_path` | Health check path | `string` | `/` |
| `enable_access_logs` | Enable access logs | `bool` | `true` |

## Outputs

| Name | Description |
|------|-------------|
| `alb_dns_name` | ALB DNS name |
| `alb_zone_id` | ALB zone ID |
| `target_group_arn` | Target group ARN |
| `security_group_id` | ALB security group ID |
