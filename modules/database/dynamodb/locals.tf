locals {
  name_prefix = "${var.project}-${var.environment}"
  table_name  = "${local.name_prefix}-${var.table_name_suffix}"

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

  # Collect all attribute definitions needed
  gsi_attributes = flatten([
    for gsi in var.global_secondary_indexes : concat(
      [{ name = gsi.hash_key, type = gsi.hash_key_type }],
      gsi.range_key != null ? [{ name = gsi.range_key, type = gsi.range_key_type }] : []
    )
  ])

  lsi_attributes = [
    for lsi in var.local_secondary_indexes : { name = lsi.range_key, type = lsi.range_key_type }
  ]

  base_attributes = concat(
    [{ name = var.hash_key, type = var.hash_key_type }],
    var.range_key != null ? [{ name = var.range_key, type = var.range_key_type }] : []
  )

  all_attributes = { for attr in concat(local.base_attributes, local.gsi_attributes, local.lsi_attributes) : attr.name => attr.type }
}
