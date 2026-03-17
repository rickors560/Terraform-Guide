resource "aws_launch_template" "this" {
  name        = "${local.name_prefix}-lt"
  description = "Launch template for ${local.name_prefix}"

  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  ebs_optimized          = var.ebs_optimized
  disable_api_termination = var.disable_api_termination
  update_default_version = var.update_default_version
  user_data              = var.user_data_base64

  monitoring {
    enabled = var.enable_monitoring
  }

  metadata_options {
    http_endpoint               = var.metadata_http_endpoint
    http_tokens                 = var.metadata_http_tokens
    http_put_response_hop_limit = var.metadata_http_put_response_hop_limit
    instance_metadata_tags      = "enabled"
  }

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_arn != null || var.iam_instance_profile_name != null ? [1] : []
    content {
      arn  = var.iam_instance_profile_arn
      name = var.iam_instance_profile_arn == null ? var.iam_instance_profile_name : null
    }
  }

  dynamic "network_interfaces" {
    for_each = length(var.security_group_ids) > 0 ? [1] : []
    content {
      associate_public_ip_address = var.associate_public_ip_address
      security_groups             = var.security_group_ids
      delete_on_termination       = true
    }
  }

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name = block_device_mappings.value.device_name

      ebs {
        volume_size           = block_device_mappings.value.ebs.volume_size
        volume_type           = block_device_mappings.value.ebs.volume_type
        encrypted             = block_device_mappings.value.ebs.encrypted
        kms_key_id            = block_device_mappings.value.ebs.kms_key_id
        delete_on_termination = block_device_mappings.value.ebs.delete_on_termination
        iops                  = block_device_mappings.value.ebs.iops
        throughput            = block_device_mappings.value.ebs.throughput
        snapshot_id           = block_device_mappings.value.ebs.snapshot_id
      }
    }
  }

  dynamic "tag_specifications" {
    for_each = var.tag_specifications_resource_types
    content {
      resource_type = tag_specifications.value

      tags = merge(
        local.common_tags,
        {
          Name = "${local.name_prefix}-${tag_specifications.value}"
        }
      )
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-lt"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
