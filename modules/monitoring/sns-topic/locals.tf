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

  topic_name = var.fifo_topic ? "${local.name_prefix}-${var.name}.fifo" : "${local.name_prefix}-${var.name}"

  subscriptions_map = { for idx, sub in var.subscriptions : "${sub.protocol}-${idx}" => sub }
}
