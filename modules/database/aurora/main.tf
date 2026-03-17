# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name        = "${local.cluster_identifier}-subnet-group"
  description = "Subnet group for ${local.cluster_identifier}"
  subnet_ids  = var.subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_identifier}-subnet-group"
    }
  )
}

# Cluster Parameter Group
resource "aws_rds_cluster_parameter_group" "this" {
  name        = "${local.cluster_identifier}-cluster-params"
  family      = var.parameter_group_family
  description = "Cluster parameter group for ${local.cluster_identifier}"

  dynamic "parameter" {
    for_each = var.cluster_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_identifier}-cluster-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Instance Parameter Group
resource "aws_db_parameter_group" "this" {
  name        = "${local.cluster_identifier}-instance-params"
  family      = var.parameter_group_family
  description = "Instance parameter group for ${local.cluster_identifier}"

  dynamic "parameter" {
    for_each = var.instance_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_identifier}-instance-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Aurora Cluster
resource "aws_rds_cluster" "this" {
  cluster_identifier = local.cluster_identifier
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = var.engine_version

  database_name                   = var.enable_global_database ? null : var.db_name
  master_username                 = var.enable_global_database ? null : var.master_username
  manage_master_user_password     = var.enable_global_database ? null : var.manage_master_user_password
  master_password                 = var.enable_global_database ? null : (var.manage_master_user_password ? null : var.master_password)
  port                            = var.port
  global_cluster_identifier       = var.enable_global_database ? var.global_cluster_identifier : null

  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = var.vpc_security_group_ids
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.name

  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  copy_tags_to_snapshot        = var.copy_tags_to_snapshot

  deletion_protection               = var.deletion_protection
  skip_final_snapshot               = var.skip_final_snapshot
  final_snapshot_identifier         = var.skip_final_snapshot ? null : "${local.cluster_identifier}-final"
  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  enabled_cloudwatch_logs_exports   = var.enabled_cloudwatch_logs_exports

  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.enable_serverless_v2 ? [1] : []
    content {
      min_capacity = var.serverless_min_capacity
      max_capacity = var.serverless_max_capacity
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.cluster_identifier
    }
  )
}

# Aurora Instances
resource "aws_rds_cluster_instance" "this" {
  count = var.instance_count

  identifier         = "${local.cluster_identifier}-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this.id
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
  instance_class     = var.enable_serverless_v2 ? "db.serverless" : var.instance_class

  db_subnet_group_name    = aws_db_subnet_group.this.name
  db_parameter_group_name = aws_db_parameter_group.this.name

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  publicly_accessible        = false

  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_retention_period = var.enable_performance_insights ? var.performance_insights_retention_period : null

  tags = merge(
    local.common_tags,
    {
      Name = "${local.cluster_identifier}-${count.index + 1}"
    }
  )
}
