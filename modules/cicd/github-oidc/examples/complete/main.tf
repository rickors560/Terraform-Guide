provider "aws" {
  region = var.aws_region
}

module "github_oidc" {
  source = "../../"

  project     = var.project
  environment = var.environment

  github_repositories = [
    {
      owner              = var.github_org
      name               = "frontend"
      branches           = ["main", "release/*"]
      environments       = ["production", "staging"]
      allow_pull_requests = false
    },
    {
      owner    = var.github_org
      name     = "backend"
      branches = ["main"]
      tags     = ["v*"]
    },
  ]

  policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser",
  ]

  inline_policies = {
    ecs-deploy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ecs:UpdateService",
            "ecs:DescribeServices",
            "ecs:DescribeTaskDefinition",
            "ecs:RegisterTaskDefinition",
            "ecs:ListTasks",
            "ecs:DescribeTasks"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "iam:PassRole"
          ]
          Resource = "*"
          Condition = {
            StringLike = {
              "iam:PassedToService" = "ecs-tasks.amazonaws.com"
            }
          }
        }
      ]
    })
  }

  additional_tags = {
    Example = "complete"
  }
}
