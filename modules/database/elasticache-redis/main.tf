# Subnet Group
resource "aws_elasticache_subnet_group" "this" {
  name        = "${local.replication_group_id}-subnet"
  description = "Subnet group for ${local.replication_group_id}"
  subnet_ids  = var.subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${local.replication_group_id}-subnet"
    }
  )
}

# Parameter Group
resource "aws_elasticache_parameter_group" "this" {
  name        = "${local.replication_group_id}-params"
  family      = var.parameter_group_family
  description = "Parameter group for ${local.replication_group_id}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.key
      value = parameter.value
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.replication_group_id}-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Replication Group
resource "aws_elasticache_replication_group" "this" {
  replication_group_id = local.replication_group_id
  description          = var.description
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = var.port

  num_cache_clusters      = var.enable_cluster_mode ? null : var.num_cache_clusters
  num_node_groups         = var.enable_cluster_mode ? var.num_node_groups : null
  replicas_per_node_group = var.enable_cluster_mode ? var.replicas_per_node_group : null

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = var.security_group_ids
  parameter_group_name = aws_elasticache_parameter_group.this.name

  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  kms_key_id                 = var.kms_key_id
  transit_encryption_enabled = var.transit_encryption_enabled
  transit_encryption_mode    = var.transit_encryption_enabled ? var.transit_encryption_mode : null
  auth_token                 = var.transit_encryption_enabled ? var.auth_token : null

  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window
  maintenance_window       = var.maintenance_window

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  notification_topic_arn     = var.notification_topic_arn
  apply_immediately          = var.apply_immediately

  tags = merge(
    local.common_tags,
    {
      Name = local.replication_group_id
    }
  )

  lifecycle {
    ignore_changes = [num_cache_clusters]
  }
}
