locals {
  name_prefix     = "${var.project}-${var.environment}"
  repository_name = "${local.name_prefix}-${var.repository_name_suffix}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Team        = var.team
      CostCenter  = var.cost_center
      Repository  = var.repository
    },
    var.additional_tags
  )
}
