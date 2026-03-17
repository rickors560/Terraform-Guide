###############################################################################
# ElastiCache Component — Redis Replication Group with Encryption & Auth
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
  #   key            = "components/elasticache/terraform.tfstate"
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
      Component   = "elasticache"
    }
  }
}

# -----------------------------------------------------------------------------
# Random Auth Token
# -----------------------------------------------------------------------------

resource "random_password" "auth_token" {
  length           = 64
  special          = true
  override_special = "!&#$^<>-"
}

# -----------------------------------------------------------------------------
# Secrets Manager — Store Auth Token
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "redis_auth" {
  name                    = "${var.project_name}/${var.environment}/elasticache/auth-token"
  description             = "ElastiCache Redis AUTH token"
  recovery_window_in_days = var.environment == "prod" ? 30 : 7

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-auth"
  }
}

resource "aws_secretsmanager_secret_version" "redis_auth" {
  secret_id = aws_secretsmanager_secret.redis_auth.id
  secret_string = jsonencode({
    auth_token       = random_password.auth_token.result
    primary_endpoint = aws_elasticache_replication_group.main.primary_endpoint_address
    reader_endpoint  = aws_elasticache_replication_group.main.reader_endpoint_address
    port             = var.port
  })
}

# -----------------------------------------------------------------------------
# Subnet Group
# -----------------------------------------------------------------------------

resource "aws_elasticache_subnet_group" "main" {
  name        = "${var.project_name}-${var.environment}-redis-subnet-group"
  description = "Redis subnet group for ${var.project_name}-${var.environment}"
  subnet_ids  = var.subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-subnet-group"
  }
}

# -----------------------------------------------------------------------------
# Parameter Group
# -----------------------------------------------------------------------------

resource "aws_elasticache_parameter_group" "main" {
  name        = "${var.project_name}-${var.environment}-redis7-params"
  family      = "redis7"
  description = "Redis 7 parameter group for ${var.project_name}-${var.environment}"

  parameter {
    name  = "maxmemory-policy"
    value = var.maxmemory_policy
  }

  parameter {
    name  = "notify-keyspace-events"
    value = var.keyspace_events
  }

  parameter {
    name  = "slowlog-log-slower-than"
    value = "10000"
  }

  parameter {
    name  = "slowlog-max-len"
    value = "128"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-redis7-params"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "redis" {
  for_each = toset(var.allowed_security_group_ids)

  security_group_id            = aws_security_group.redis.id
  description                  = "Redis access from allowed SG"
  ip_protocol                  = "tcp"
  from_port                    = var.port
  to_port                      = var.port
  referenced_security_group_id = each.value

  tags = { Name = "redis-from-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "redis_cidr" {
  for_each = toset(var.allowed_cidr_blocks)

  security_group_id = aws_security_group.redis.id
  description       = "Redis access from CIDR"
  ip_protocol       = "tcp"
  from_port         = var.port
  to_port           = var.port
  cidr_ipv4         = each.value

  tags = { Name = "redis-from-cidr" }
}

resource "aws_vpc_security_group_egress_rule" "all" {
  security_group_id = aws_security_group.redis.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  tags              = { Name = "all-outbound" }
}

# -----------------------------------------------------------------------------
# ElastiCache Replication Group
# -----------------------------------------------------------------------------

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.project_name}-${var.environment}-redis"
  description          = "Redis replication group for ${var.project_name}-${var.environment}"

  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = var.port
  parameter_group_name = aws_elasticache_parameter_group.main.name
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]

  num_cache_clusters = var.num_cache_clusters

  automatic_failover_enabled = var.num_cache_clusters > 1
  multi_az_enabled           = var.num_cache_clusters > 1

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.auth_token.result
  kms_key_id                 = var.kms_key_arn != "" ? var.kms_key_arn : null

  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = "03:00-05:00"
  maintenance_window       = "Mon:05:00-Mon:07:00"

  auto_minor_version_upgrade = true
  apply_immediately          = var.environment != "prod"

  notification_topic_arn = var.notification_topic_arn != "" ? var.notification_topic_arn : null

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_slow_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  log_delivery_configuration {
    destination      = aws_cloudwatch_log_group.redis_engine_log.name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "engine-log"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-redis"
  }

  lifecycle {
    ignore_changes = [auth_token]
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Log Groups
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "redis_slow_log" {
  name              = "/aws/elasticache/${var.project_name}-${var.environment}-redis/slow-log"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-slow-log"
  }
}

resource "aws_cloudwatch_log_group" "redis_engine_log" {
  name              = "/aws/elasticache/${var.project_name}-${var.environment}-redis/engine-log"
  retention_in_days = 30

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-engine-log"
  }
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms
# -----------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-${var.environment}-redis-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Redis engine CPU utilization exceeds 80%"
  treat_missing_data  = "missing"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${var.project_name}-${var.environment}-redis-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "DatabaseMemoryUsagePercentage"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Redis memory usage exceeds 80%"
  treat_missing_data  = "missing"

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-memory-alarm"
  }
}
