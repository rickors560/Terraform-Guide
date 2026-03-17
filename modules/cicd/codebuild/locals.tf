locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Team        = var.team
      CostCenter  = var.cost_center
      Repository  = var.repository
    },
    var.additional_tags,
  )

  project_name = "${local.name_prefix}-${var.build_project_name}"

  # Merge plaintext and SSM environment variables
  environment_variables = concat(
    [for k, v in var.environment_variables : {
      name  = k
      value = v
      type  = "PLAINTEXT"
    }],
    [for k, v in var.environment_variables_ssm : {
      name  = k
      value = v
      type  = "PARAMETER_STORE"
    }],
    [for k, v in var.environment_variables_secrets_manager : {
      name  = k
      value = v
      type  = "SECRETS_MANAGER"
    }],
  )
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}
