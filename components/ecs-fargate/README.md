# ECS Fargate Component

Production-grade ECS Fargate service with ALB, auto-scaling, Container Insights, and ECS Exec support.

## Features

- ECS cluster with Container Insights and FARGATE/FARGATE_SPOT capacity providers
- Task definition with health check, logging, and environment variables
- Service with deployment circuit breaker and rollback
- ALB with HTTP-to-HTTPS redirect and TLS 1.3 support
- Auto-scaling based on CPU and memory utilization
- ECS Exec enabled for debugging
- Separate security groups for ALB and tasks

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply

# Access the service
curl http://$(terraform output -raw alb_dns_name)

# Debug with ECS Exec
aws ecs execute-command --cluster $(terraform output -raw cluster_name) \
  --task TASK_ID --container app --interactive --command "/bin/sh"
```

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vpc_id` | VPC ID | `string` | — |
| `public_subnet_ids` | ALB subnets | `list(string)` | — |
| `private_subnet_ids` | Task subnets | `list(string)` | — |
| `container_image` | Docker image | `string` | `nginx:latest` |
| `task_cpu` | CPU units | `number` | `256` |
| `task_memory` | Memory (MB) | `number` | `512` |
| `desired_count` | Task count | `number` | `2` |

## Outputs

| Name | Description |
|------|-------------|
| `alb_dns_name` | ALB DNS name |
| `cluster_name` | ECS cluster name |
| `service_name` | ECS service name |
