provider "aws" {
  region = var.aws_region
}

module "ecs_fargate" {
  source = "../../"

  project      = var.project
  environment  = var.environment
  service_name = "api"

  task_cpu    = 512
  task_memory = 1024

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project}-${var.environment}-api"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_group_ids
  desired_count      = 2

  enable_autoscaling       = true
  autoscaling_min_capacity = 2
  autoscaling_max_capacity = 10
  autoscaling_cpu_target   = 70

  enable_execute_command = true

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
