# Containers Modules

Terraform modules for deploying and managing AWS container services including EKS (Kubernetes), ECS Fargate (serverless containers), and ECR (container image registry).

## Sub-Modules

| Module | Description |
|--------|-------------|
| [eks/](./eks/) | Collection of EKS modules for cluster, node groups, add-ons, and IRSA (see [eks/README.md](./eks/README.md) for details) |
| [ecs-fargate](./ecs-fargate/) | ECS Fargate cluster, task definition, and service with auto scaling, load balancer integration, and ECS Exec |
| [ecr](./ecr/) | ECR repository with image scanning, lifecycle policies, encryption, and cross-account access |

## How They Relate

```
ecr (Container Registry)
 |
 |  docker push / pull
 |
 +--------+--------+
 |                  |
 v                  v
eks              ecs-fargate
(Kubernetes)     (Serverless Containers)
```

- **ecr** stores container images that are pulled by both **eks** and **ecs-fargate** workloads at runtime.
- **eks** provides a full Kubernetes control plane with managed node groups, suitable for complex microservice architectures.
- **ecs-fargate** runs serverless containers without managing the underlying infrastructure, suitable for simpler services.

Choose EKS when you need Kubernetes-native tooling, Helm charts, or complex scheduling. Choose ECS Fargate when you want a simpler operational model without managing nodes.

## Usage Example

```hcl
# Container registry for application images
module "ecr" {
  source = "../../modules/containers/ecr"

  project                = "myapp"
  environment            = "prod"
  repository_name_suffix = "api"

  image_tag_mutability       = "IMMUTABLE"
  scan_on_push               = true
  max_tagged_image_count     = 30
  untagged_image_expiry_days = 7

  team = "platform"
}

# ECS Fargate service pulling from ECR
module "ecs_service" {
  source = "../../modules/containers/ecs-fargate"

  project      = "myapp"
  environment  = "prod"
  service_name = "api"

  task_cpu    = 512
  task_memory = 1024

  container_definitions = jsonencode([
    {
      name  = "api"
      image = "${module.ecr.repository_url}:latest"
      portMappings = [{ containerPort = 8080 }]
    }
  ])

  subnet_ids         = module.vpc.private_subnet_ids
  security_group_ids = [module.app_sg.security_group_id]
  desired_count      = 2

  enable_load_balancer = true
  lb_target_group_arn  = module.alb.target_group_arn
  lb_container_name    = "api"
  lb_container_port    = 8080

  team = "platform"
}
```
