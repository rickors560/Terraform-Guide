locals {
  name_prefix = "${var.project}-${var.environment}"
  identifier  = "${local.name_prefix}-postgres"

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
