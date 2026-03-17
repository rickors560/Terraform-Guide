locals {
  name_prefix        = "${var.project}-${var.environment}"
  replication_group_id = "${local.name_prefix}-redis"

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
