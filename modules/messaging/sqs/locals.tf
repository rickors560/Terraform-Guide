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

  queue_name     = var.fifo_queue ? "${local.name_prefix}-${var.name}.fifo" : "${local.name_prefix}-${var.name}"
  dlq_queue_name = var.fifo_queue ? "${local.name_prefix}-${var.name}-dlq.fifo" : "${local.name_prefix}-${var.name}-dlq"
}
