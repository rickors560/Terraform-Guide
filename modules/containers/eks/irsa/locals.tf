locals {
  name_prefix = "${var.project}-${var.environment}"
  role_name   = "${local.name_prefix}-${var.role_name_suffix}"

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
