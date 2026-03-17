resource "aws_ebs_volume" "this" {
  availability_zone    = var.availability_zone
  type                 = var.type
  size                 = var.size
  iops                 = var.iops
  throughput           = var.type == "gp3" ? var.throughput : null
  encrypted            = var.encrypted
  kms_key_id           = var.kms_key_id
  snapshot_id          = var.snapshot_id
  multi_attach_enabled = var.multi_attach_enabled
  final_snapshot       = var.final_snapshot

  tags = merge(
    local.common_tags,
    {
      Name = local.volume_name
    }
  )
}
