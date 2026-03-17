###############################################################################
# Secrets Manager Secret
###############################################################################

resource "aws_secretsmanager_secret" "this" {
  name                    = "${local.name_prefix}/${var.name}"
  description             = var.description
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_in_days

  dynamic "replica" {
    for_each = var.replica_regions
    content {
      region     = replica.value.region
      kms_key_id = replica.value.kms_key_id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}/${var.name}"
  })
}

###############################################################################
# Secret Value
###############################################################################

resource "aws_secretsmanager_secret_version" "this" {
  count = var.secret_string != null || var.secret_binary != null ? 1 : 0

  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.secret_string
  secret_binary = var.secret_binary

  lifecycle {
    ignore_changes = [
      secret_string,
      secret_binary,
    ]
  }
}

###############################################################################
# Secret Rotation
###############################################################################

resource "aws_secretsmanager_secret_rotation" "this" {
  count = var.enable_rotation ? 1 : 0

  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = var.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = var.rotation_days
  }
}

###############################################################################
# Secret Policy
###############################################################################

resource "aws_secretsmanager_secret_policy" "this" {
  count = var.policy != null ? 1 : 0

  secret_arn = aws_secretsmanager_secret.this.arn
  policy     = var.policy
}
