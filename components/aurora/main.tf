###############################################################################
# Aurora Component — Aurora PostgreSQL Cluster with Auto-Scaling
###############################################################################

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "components/aurora/terraform.tfstate"
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "aurora"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

# -----------------------------------------------------------------------------
# Random Password
# -----------------------------------------------------------------------------

resource "random_password" "master" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# -----------------------------------------------------------------------------
# Secrets Manager
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "aurora_credentials" {
  name                    = "${var.project_name}/${var.environment}/aurora/credentials"
  description             = "Aurora PostgreSQL master credentials"
  recovery_window_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-credentials"
  }
}

resource "aws_secretsmanager_secret_version" "aurora_credentials" {
  secret_id = aws_secretsmanager_secret.aurora_credentials.id
  secret_string = jsonencode({
    username = var.master_username
    password = random_password.master.result
    engine   = "aurora-postgresql"
    host     = aws_rds_cluster.main.endpoint
    port     = aws_rds_cluster.main.port
    dbname   = var.database_name
  })
}

# -----------------------------------------------------------------------------
# DB Subnet Group
# -----------------------------------------------------------------------------

resource "aws_db_subnet_group" "aurora" {
  name        = "${var.project_name}-${var.environment}-aurora-subnet-group"
  description = "Aurora subnet group for ${var.project_name}-${var.environment}"
  subnet_ids  = var.subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-subnet-group"
  }
}

# -----------------------------------------------------------------------------
# Cluster Parameter Group
# -----------------------------------------------------------------------------

resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${var.project_name}-${var.environment}-aurora-pg16-cluster-params"
  family      = "aurora-postgresql16"
  description = "Aurora PostgreSQL 16 cluster parameter group"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-cluster-params"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Instance Parameter Group
# -----------------------------------------------------------------------------

resource "aws_db_parameter_group" "aurora" {
  name        = "${var.project_name}-${var.environment}-aurora-pg16-instance-params"
  family      = "aurora-postgresql16"
  description = "Aurora PostgreSQL 16 instance parameter group"

  parameter {
    name  = "log_statement"
    value = "ddl"
  }

  parameter {
    name  = "pg_stat_statements.track"
    value = "all"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-instance-params"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "aurora" {
  name        = "${var.project_name}-${var.environment}-aurora-sg"
  description = "Security group for Aurora PostgreSQL cluster"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "postgres" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.aurora.id
  description                  = "PostgreSQL from allowed SG"
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  referenced_security_group_id = each.value

  tags = { Name = "postgres-from-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "postgres_cidr" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.aurora.id
  description       = "PostgreSQL from CIDR"
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
  cidr_ipv4         = each.value

  tags = { Name = "postgres-from-cidr" }
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.aurora.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "all-outbound" }
}

# -----------------------------------------------------------------------------
# Aurora Cluster
# -----------------------------------------------------------------------------

resource "aws_rds_cluster" "main" {
  cluster_identifier = "${var.project_name}-${var.environment}-aurora-pg"

  engine         = "aurora-postgresql"
  engine_version = var.engine_version
  engine_mode    = "provisioned"

  database_name   = var.database_name
  master_username = var.master_username
  master_password = random_password.master.result
  port            = 5432

  db_subnet_group_name            = aws_db_subnet_group.aurora.name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  vpc_security_group_ids          = [aws_security_group.aurora.id]

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn != "" ? var.kms_key_arn : null

  backup_retention_period   = var.backup_retention_period
  preferred_backup_window   = "03:00-04:00"
  preferred_maintenance_window = "Mon:04:00-Mon:05:00"
  copy_tags_to_snapshot     = true
  deletion_protection       = var.environment == "prod"
  skip_final_snapshot       = var.environment != "prod"
  final_snapshot_identifier = var.environment == "prod" ? "${var.project_name}-${var.environment}-aurora-final" : null

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-pg"
  }

  lifecycle {
    ignore_changes = [master_password]
  }
}

# -----------------------------------------------------------------------------
# Aurora Instances
# -----------------------------------------------------------------------------

resource "aws_rds_cluster_instance" "main" {
  count = var.instance_count

  identifier         = "${var.project_name}-${var.environment}-aurora-pg-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main.id

  engine         = aws_rds_cluster.main.engine
  engine_version = aws_rds_cluster.main.engine_version
  instance_class = var.instance_class

  db_parameter_group_name = aws_db_parameter_group.aurora.name
  db_subnet_group_name    = aws_db_subnet_group.aurora.name

  publicly_accessible          = false
  auto_minor_version_upgrade   = true
  performance_insights_enabled = true

  monitoring_interval = var.enhanced_monitoring_interval
  monitoring_role_arn = var.enhanced_monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-pg-${count.index + 1}"
  }
}

# -----------------------------------------------------------------------------
# Enhanced Monitoring IAM Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "rds_monitoring" {
  count = var.enhanced_monitoring_interval > 0 ? 1 : 0

  name = "${var.project_name}-${var.environment}-aurora-monitoring-role"

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

  tags = {
    Name = "${var.project_name}-${var.environment}-aurora-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.enhanced_monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# -----------------------------------------------------------------------------
# Auto-Scaling (Read Replicas)
# -----------------------------------------------------------------------------

resource "aws_appautoscaling_target" "aurora_replicas" {
  count = var.enable_autoscaling ? 1 : 0

  service_namespace  = "rds"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  resource_id        = "cluster:${aws_rds_cluster.main.id}"
  min_capacity       = var.autoscaling_min_capacity
  max_capacity       = var.autoscaling_max_capacity
}

resource "aws_appautoscaling_policy" "aurora_replicas" {
  count = var.enable_autoscaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-aurora-autoscaling"
  service_namespace  = aws_appautoscaling_target.aurora_replicas[0].service_namespace
  scalable_dimension = aws_appautoscaling_target.aurora_replicas[0].scalable_dimension
  resource_id        = aws_appautoscaling_target.aurora_replicas[0].resource_id
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"
    }
    target_value       = var.autoscaling_target_cpu
    scale_in_cooldown  = 300
    scale_out_cooldown = 300
  }
}
