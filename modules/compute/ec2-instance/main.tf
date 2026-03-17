resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = var.key_name
  iam_instance_profile        = var.iam_instance_profile_name
  monitoring                  = var.enable_detailed_monitoring
  ebs_optimized               = var.ebs_optimized
  disable_api_termination     = var.disable_api_termination
  associate_public_ip_address = var.associate_public_ip_address
  private_ip                  = var.private_ip
  user_data                   = var.user_data
  user_data_base64            = var.user_data_base64

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    encrypted             = var.root_volume_encrypted
    kms_key_id            = var.root_volume_kms_key_id
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = var.metadata_http_endpoint
    http_tokens                 = var.metadata_http_tokens
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-instance"
    }
  )

  volume_tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-root-volume"
    }
  )

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_eip" "this" {
  count  = var.associate_eip ? 1 : 0
  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-eip"
    }
  )
}

resource "aws_eip_association" "this" {
  count         = var.associate_eip ? 1 : 0
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this[0].id
}
