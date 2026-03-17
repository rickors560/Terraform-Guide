# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name        = "${local.identifier}-subnet-group"
  description = "Subnet group for ${local.identifier}"
  subnet_ids  = var.subnet_ids

  tags = merge(
    local.common_tags,
    {
      Name = "${local.identifier}-subnet-group"
    }
  )
}

# Parameter Group
resource "aws_db_parameter_group" "this" {
  name        = "${local.identifier}-params"
  family      = var.parameter_group_family
  description = "Parameter group for ${local.identifier}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.identifier}-params"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Enhanced Monitoring IAM Role
resource "aws_iam_role" "enhanced_monitoring" {
  count = var.enable_enhanced_monitoring ? 1 : 0
  name  = "${local.identifier}-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${local.identifier}-monitoring-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  count      = var.enable_enhanced_monitoring ? 1 : 0
  role       = aws_iam_role.enhanced_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS Instance
resource "aws_db_instance" "this" {
  identifier     = local.identifier
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id

  db_name                     = var.db_name
  username                    = var.username
  manage_master_user_password = var.manage_master_user_password
  password                    = var.manage_master_user_password ? null : var.password
  port                        = var.port

  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.vpc_security_group_ids
  publicly_accessible    = var.publicly_accessible
  parameter_group_name   = aws_db_parameter_group.this.name

  backup_retention_period = var.backup_retention_period
  backup_window           = var.backup_window
  maintenance_window      = var.maintenance_window

  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  deletion_protection        = var.deletion_protection
  skip_final_snapshot        = var.skip_final_snapshot
  final_snapshot_identifier  = var.skip_final_snapshot ? null : "${local.identifier}-${var.final_snapshot_identifier_suffix}"
  copy_tags_to_snapshot      = var.copy_tags_to_snapshot

  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_retention_period = var.enable_performance_insights ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.enable_performance_insights ? var.performance_insights_kms_key_id : null

  monitoring_interval = var.enable_enhanced_monitoring ? var.monitoring_interval : 0
  monitoring_role_arn = var.enable_enhanced_monitoring ? aws_iam_role.enhanced_monitoring[0].arn : null

  iam_database_authentication_enabled = var.iam_database_authentication_enabled
  enabled_cloudwatch_logs_exports     = var.enabled_cloudwatch_logs_exports

  tags = merge(
    local.common_tags,
    {
      Name = local.identifier
    }
  )
}
