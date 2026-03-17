###############################################################################
# DynamoDB Component — Table with GSI, LSI, TTL, PITR, Auto-Scaling
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
  #   key            = "components/dynamodb/terraform.tfstate"
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
      Component   = "dynamodb"
    }
  }
}

# -----------------------------------------------------------------------------
# DynamoDB Table
# -----------------------------------------------------------------------------

resource "aws_dynamodb_table" "main" {
  name         = "${var.project_name}-${var.environment}-${var.table_name}"
  billing_mode = var.billing_mode

  # Provisioned capacity (only applies when billing_mode = PROVISIONED)
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  hash_key  = var.hash_key
  range_key = var.range_key

  # Partition key
  attribute {
    name = var.hash_key
    type = var.hash_key_type
  }

  # Sort key
  attribute {
    name = var.range_key
    type = var.range_key_type
  }

  # GSI attributes
  attribute {
    name = "GSI1PK"
    type = "S"
  }

  attribute {
    name = "GSI1SK"
    type = "S"
  }

  # LSI attribute
  attribute {
    name = "LSI1SK"
    type = "S"
  }

  # Global Secondary Index
  global_secondary_index {
    name            = "GSI1"
    hash_key        = "GSI1PK"
    range_key       = "GSI1SK"
    projection_type = "ALL"
    read_capacity   = var.billing_mode == "PROVISIONED" ? var.gsi_read_capacity : null
    write_capacity  = var.billing_mode == "PROVISIONED" ? var.gsi_write_capacity : null
  }

  # Local Secondary Index
  local_secondary_index {
    name            = "LSI1"
    range_key       = "LSI1SK"
    projection_type = "ALL"
  }

  # Time-to-Live
  ttl {
    attribute_name = var.ttl_attribute
    enabled        = var.ttl_enabled
  }

  # Point-in-Time Recovery
  point_in_time_recovery {
    enabled = var.pitr_enabled
  }

  # Server-Side Encryption
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn != "" ? var.kms_key_arn : null
  }

  # Stream (useful for Lambda triggers and replication)
  stream_enabled   = var.stream_enabled
  stream_view_type = var.stream_enabled ? var.stream_view_type : null

  # Deletion protection
  deletion_protection_enabled = var.environment == "prod"

  tags = {
    Name = "${var.project_name}-${var.environment}-${var.table_name}"
  }

  lifecycle {
    ignore_changes = [
      read_capacity,
      write_capacity,
    ]
  }
}

# -----------------------------------------------------------------------------
# Auto-Scaling (only for PROVISIONED billing mode)
# -----------------------------------------------------------------------------

# Read capacity auto-scaling
resource "aws_appautoscaling_target" "read" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_read_max
  min_capacity       = var.autoscaling_read_min
  resource_id        = "table/${aws_dynamodb_table.main.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "read" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-${var.table_name}-read-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read[0].resource_id
  scalable_dimension = aws_appautoscaling_target.read[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.read[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value       = var.autoscaling_target_utilization
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# Write capacity auto-scaling
resource "aws_appautoscaling_target" "write" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_write_max
  min_capacity       = var.autoscaling_write_min
  resource_id        = "table/${aws_dynamodb_table.main.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "write" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-${var.table_name}-write-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.write[0].resource_id
  scalable_dimension = aws_appautoscaling_target.write[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.write[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value       = var.autoscaling_target_utilization
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}

# GSI Read capacity auto-scaling
resource "aws_appautoscaling_target" "gsi_read" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_read_max
  min_capacity       = var.autoscaling_read_min
  resource_id        = "table/${aws_dynamodb_table.main.name}/index/GSI1"
  scalable_dimension = "dynamodb:index:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "gsi_read" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-${var.table_name}-gsi-read-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.gsi_read[0].resource_id
  scalable_dimension = aws_appautoscaling_target.gsi_read[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.gsi_read[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = var.autoscaling_target_utilization
  }
}

# GSI Write capacity auto-scaling
resource "aws_appautoscaling_target" "gsi_write" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  max_capacity       = var.autoscaling_write_max
  min_capacity       = var.autoscaling_write_min
  resource_id        = "table/${aws_dynamodb_table.main.name}/index/GSI1"
  scalable_dimension = "dynamodb:index:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "gsi_write" {
  count = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0

  name               = "${var.project_name}-${var.environment}-${var.table_name}-gsi-write-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.gsi_write[0].resource_id
  scalable_dimension = aws_appautoscaling_target.gsi_write[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.gsi_write[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = var.autoscaling_target_utilization
  }
}
