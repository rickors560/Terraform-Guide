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

  report_name = "${local.name_prefix}-${var.report_name}"
  bucket_name = var.create_s3_bucket ? "${local.name_prefix}-cur-${data.aws_caller_identity.current.account_id}" : var.s3_bucket_name
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
