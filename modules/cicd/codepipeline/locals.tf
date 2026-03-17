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

  pipeline_name       = "${local.name_prefix}-${var.pipeline_name}"
  artifact_bucket_name = var.create_artifact_bucket ? "${local.name_prefix}-codepipeline-artifacts-${data.aws_caller_identity.current.account_id}" : null
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}
