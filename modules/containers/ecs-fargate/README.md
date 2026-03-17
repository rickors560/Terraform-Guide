# ECS Fargate Module

Terraform module to create an AWS ECS Fargate cluster, task definition, and service with auto scaling, load balancer integration, service discovery, and execute command support.

## Features

- ECS cluster with Container Insights
- Fargate task definition (CPU, memory, container definitions)
- Service with configurable desired count
- Network configuration (subnets, security groups)
- Load balancer integration
- Auto scaling (target tracking on CPU/memory)
- Service discovery option
- ECS Exec support
- Deployment circuit breaker with rollback
- EFS volume support

## Usage

```hcl
module "ecs" {
  source = "../../modules/containers/ecs-fargate"

  project      = "myapp"
  environment  = "prod"
  service_name = "api"

  task_cpu    = 512
  task_memory = 1024

  container_definitions = jsonencode([
    {
      name  = "api"
      image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/myapp:latest"
      portMappings = [{ containerPort = 8080 }]
    }
  ])

  subnet_ids         = ["subnet-xxx", "subnet-yyy"]
  security_group_ids = ["sg-xxx"]
  desired_count      = 2

  enable_load_balancer = true
  lb_target_group_arn  = "arn:aws:..."
  lb_container_name    = "api"
  lb_container_port    = 8080

  enable_autoscaling       = true
  autoscaling_min_capacity = 2
  autoscaling_max_capacity = 10

  team = "platform"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.9.0 |
| aws | ~> 5.0 |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | ECS cluster ID |
| cluster_arn | ECS cluster ARN |
| service_id | ECS service ID |
| task_definition_arn | Task definition ARN |
