resource "aws_efs_file_system" "this" {
  encrypted                       = var.encrypted
  kms_key_id                      = var.kms_key_id
  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput_in_mibps : null

  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy_transition_to_ia != null ? [1] : []
    content {
      transition_to_ia = var.lifecycle_policy_transition_to_ia
    }
  }

  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy_transition_to_primary != null ? [1] : []
    content {
      transition_to_primary_storage_class = var.lifecycle_policy_transition_to_primary
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-efs"
    }
  )
}

resource "aws_efs_backup_policy" "this" {
  file_system_id = aws_efs_file_system.this.id

  backup_policy {
    status = var.enable_backup ? "ENABLED" : "DISABLED"
  }
}

resource "aws_efs_mount_target" "this" {
  count = length(var.subnet_ids)

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = var.security_group_ids
}

resource "aws_efs_access_point" "this" {
  count = length(var.access_points)

  file_system_id = aws_efs_file_system.this.id

  dynamic "posix_user" {
    for_each = var.access_points[count.index].posix_user != null ? [var.access_points[count.index].posix_user] : []
    content {
      uid            = posix_user.value.uid
      gid            = posix_user.value.gid
      secondary_gids = posix_user.value.secondary_gids
    }
  }

  dynamic "root_directory" {
    for_each = var.access_points[count.index].root_directory != null ? [var.access_points[count.index].root_directory] : []
    content {
      path = root_directory.value.path

      dynamic "creation_info" {
        for_each = root_directory.value.creation_info != null ? [root_directory.value.creation_info] : []
        content {
          owner_uid   = creation_info.value.owner_uid
          owner_gid   = creation_info.value.owner_gid
          permissions = creation_info.value.permissions
        }
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-efs-ap-${var.access_points[count.index].name}"
    }
  )
}
