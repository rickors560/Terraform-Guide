# NLB Component

Production-grade Network Load Balancer with TCP/TLS listeners, target group, cross-zone balancing, and health checks.

## Features

- TCP listener with optional TLS termination
- Cross-zone load balancing
- Client IP preservation
- TCP or HTTP health checks
- Source IP stickiness (optional)
- Proxy Protocol v2 support (optional)
- CloudWatch alarms for unhealthy hosts and active flows

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
| `subnet_ids` | Subnet IDs | `list(string)` | -- |
| `listener_port` | TCP listener port | `number` | `80` |
| `target_port` | Target port | `number` | `80` |
| `enable_cross_zone_load_balancing` | Cross-zone LB | `bool` | `true` |

## Outputs

| Name | Description |
|------|-------------|
| `nlb_dns_name` | NLB DNS name |
| `nlb_zone_id` | NLB zone ID |
| `target_group_arn` | Target group ARN |
