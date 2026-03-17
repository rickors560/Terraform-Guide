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

  bus_name = var.create_bus ? "${local.name_prefix}-${var.bus_name}" : var.bus_name

  rules_map = { for rule in var.rules : rule.name => rule }

  # Flatten targets for resources
  rule_targets = flatten([
    for rule in var.rules : [
      for idx, target in rule.targets : {
        rule_name       = rule.name
        target_key      = "${rule.name}-${idx}"
        target_id       = target.target_id
        arn             = target.arn
        role_arn        = target.role_arn
        input           = target.input
        input_path      = target.input_path
        input_transformer = target.input_transformer
        dead_letter_arn = target.dead_letter_arn
        retry_policy    = target.retry_policy
        sqs_target      = target.sqs_target
        ecs_target      = target.ecs_target
      }
    ]
  ])

  rule_targets_map = { for t in local.rule_targets : t.target_key => t }
}
