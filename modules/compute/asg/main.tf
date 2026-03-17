resource "aws_autoscaling_group" "this" {
  name                      = "${local.name_prefix}-asg"
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  target_group_arns         = var.target_group_arns
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  default_cooldown          = var.default_cooldown
  force_delete              = var.force_delete
  termination_policies      = var.termination_policies
  suspended_processes       = var.suspended_processes
  wait_for_capacity_timeout = var.wait_for_capacity_timeout
  protect_from_scale_in     = var.protect_from_scale_in
  enabled_metrics           = var.enabled_metrics

  dynamic "launch_template" {
    for_each = var.enable_mixed_instances_policy ? [] : [1]
    content {
      id      = var.launch_template_id
      version = var.launch_template_version
    }
  }

  dynamic "mixed_instances_policy" {
    for_each = var.enable_mixed_instances_policy ? [1] : []
    content {
      launch_template {
        launch_template_specification {
          launch_template_id = var.launch_template_id
          version            = var.launch_template_version
        }

        dynamic "override" {
          for_each = var.mixed_instances_override
          content {
            instance_type     = override.value.instance_type
            weighted_capacity = override.value.weighted_capacity
          }
        }
      }

      instances_distribution {
        on_demand_base_capacity                  = var.on_demand_base_capacity
        on_demand_percentage_above_base_capacity = var.on_demand_percentage_above_base_capacity
        spot_allocation_strategy                 = var.spot_allocation_strategy
      }
    }
  }

  dynamic "instance_refresh" {
    for_each = var.enable_instance_refresh ? [1] : []
    content {
      strategy = var.instance_refresh_strategy

      preferences {
        min_healthy_percentage = var.instance_refresh_min_healthy_percentage
        instance_warmup        = var.instance_refresh_instance_warmup
      }
    }
  }

  dynamic "warm_pool" {
    for_each = var.enable_warm_pool ? [1] : []
    content {
      pool_state                  = var.warm_pool_state
      min_size                    = var.warm_pool_min_size
      max_group_prepared_capacity = var.warm_pool_max_group_prepared_capacity
      instance_reuse_policy {
        reuse_on_scale_in = var.warm_pool_reuse_on_scale_in
      }
    }
  }

  dynamic "tag" {
    for_each = merge(
      local.common_tags,
      {
        Name = "${local.name_prefix}-asg"
      }
    )
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  count = var.enable_target_tracking_cpu ? 1 : 0

  name                   = "${local.name_prefix}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value     = var.target_cpu_value
    disable_scale_in = false
  }
}

resource "aws_autoscaling_policy" "alb_request_count_target_tracking" {
  count = var.enable_target_tracking_alb_request_count ? 1 : 0

  name                   = "${local.name_prefix}-alb-request-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = var.alb_target_group_arn
    }

    target_value     = var.target_alb_request_count_value
    disable_scale_in = false
  }
}
