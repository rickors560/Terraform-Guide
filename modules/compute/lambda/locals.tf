locals {
  name_prefix   = "${var.project}-${var.environment}"
  function_name = "${local.name_prefix}-${var.function_name_suffix}"

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

  enable_vpc = length(var.vpc_subnet_ids) > 0 && length(var.vpc_security_group_ids) > 0
}
