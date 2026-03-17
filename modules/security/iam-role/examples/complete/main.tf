provider "aws" {
  region = var.aws_region
}

module "ecs_task_role" {
  source = "../../"

  project     = var.project
  environment = var.environment
  name        = "ecs-task"
  description = "ECS task execution role"

  trusted_services     = ["ecs-tasks.amazonaws.com"]
  max_session_duration = 3600

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]

  inline_policies = {
    ssm-access = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["ssm:GetParameters", "ssm:GetParameter"]
          Resource = "arn:aws:ssm:*:*:parameter/${var.project}/${var.environment}/*"
        },
      ]
    })
  }

  team        = var.team
  cost_center = var.cost_center
}

module "ec2_instance_role" {
  source = "../../"

  project     = var.project
  environment = var.environment
  name        = "ec2-instance"
  description = "EC2 instance role with SSM access"

  trusted_services        = ["ec2.amazonaws.com"]
  create_instance_profile = true

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]

  team        = var.team
  cost_center = var.cost_center
}
