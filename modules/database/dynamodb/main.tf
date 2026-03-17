resource "aws_dynamodb_table" "this" {
  name         = local.table_name
  billing_mode = var.billing_mode
  hash_key     = var.hash_key
  range_key    = var.range_key

  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  deletion_protection_enabled = var.deletion_protection_enabled

  dynamic "attribute" {
    for_each = local.all_attributes
    content {
      name = attribute.key
      type = attribute.value
    }
  }

  dynamic "ttl" {
    for_each = var.ttl_attribute != "" ? [1] : []
    content {
      attribute_name = var.ttl_attribute
      enabled        = true
    }
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery_enabled
  }

  server_side_encryption {
    enabled     = var.server_side_encryption_enabled
    kms_key_arn = var.server_side_encryption_kms_key_arn
  }

  dynamic "stream_specification" {
    for_each = var.stream_enabled ? [1] : []
    content {
      stream_enabled   = true
      stream_view_type = var.stream_view_type
    }
  }

  dynamic "global_secondary_index" {
    for_each = var.global_secondary_indexes
    content {
      name               = global_secondary_index.value.name
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      projection_type    = global_secondary_index.value.projection_type
      non_key_attributes = global_secondary_index.value.non_key_attributes
      read_capacity      = var.billing_mode == "PROVISIONED" ? global_secondary_index.value.read_capacity : null
      write_capacity     = var.billing_mode == "PROVISIONED" ? global_secondary_index.value.write_capacity : null
    }
  }

  dynamic "local_secondary_index" {
    for_each = var.local_secondary_indexes
    content {
      name               = local_secondary_index.value.name
      range_key          = local_secondary_index.value.range_key
      projection_type    = local_secondary_index.value.projection_type
      non_key_attributes = local_secondary_index.value.non_key_attributes
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.table_name
    }
  )
}

# Auto Scaling for PROVISIONED mode
resource "aws_appautoscaling_target" "read" {
  count              = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0
  max_capacity       = var.autoscaling_read_max_capacity
  min_capacity       = var.autoscaling_read_min_capacity
  resource_id        = "table/${aws_dynamodb_table.this.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "read" {
  count              = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0
  name               = "${local.table_name}-read-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.read[0].resource_id
  scalable_dimension = aws_appautoscaling_target.read[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.read[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }
    target_value = var.autoscaling_target_value
  }
}

resource "aws_appautoscaling_target" "write" {
  count              = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0
  max_capacity       = var.autoscaling_write_max_capacity
  min_capacity       = var.autoscaling_write_min_capacity
  resource_id        = "table/${aws_dynamodb_table.this.name}"
  scalable_dimension = "dynamodb:table:WriteCapacityUnits"
  service_namespace  = "dynamodb"
}

resource "aws_appautoscaling_policy" "write" {
  count              = var.billing_mode == "PROVISIONED" && var.enable_autoscaling ? 1 : 0
  name               = "${local.table_name}-write-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.write[0].resource_id
  scalable_dimension = aws_appautoscaling_target.write[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.write[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBWriteCapacityUtilization"
    }
    target_value = var.autoscaling_target_value
  }
}
