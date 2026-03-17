###############################################################################
# Data Sources
###############################################################################

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

###############################################################################
# Key Policy
###############################################################################

data "aws_iam_policy_document" "key_policy" {
  count = var.key_policy == null ? 1 : 0

  # Root account access
  statement {
    sid    = "EnableRootAccountAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # Key administrators
  dynamic "statement" {
    for_each = length(var.key_administrators) > 0 ? [1] : []
    content {
      sid    = "KeyAdministrators"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.key_administrators
      }
      actions = [
        "kms:Create*",
        "kms:Describe*",
        "kms:Enable*",
        "kms:List*",
        "kms:Put*",
        "kms:Update*",
        "kms:Revoke*",
        "kms:Disable*",
        "kms:Get*",
        "kms:Delete*",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:ScheduleKeyDeletion",
        "kms:CancelKeyDeletion",
        "kms:ReplicateKey",
        "kms:UpdatePrimaryRegion",
      ]
      resources = ["*"]
    }
  }

  # Key users
  dynamic "statement" {
    for_each = length(var.key_users) > 0 ? [1] : []
    content {
      sid    = "KeyUsers"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.key_users
      }
      actions = [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey",
      ]
      resources = ["*"]
    }
  }

  # Service users (grant-based access)
  dynamic "statement" {
    for_each = length(var.key_service_users) > 0 ? [1] : []
    content {
      sid    = "KeyServiceUsers"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.key_service_users
      }
      actions = [
        "kms:CreateGrant",
        "kms:ListGrants",
        "kms:RevokeGrant",
      ]
      resources = ["*"]
      condition {
        test     = "Bool"
        variable = "kms:GrantIsForAWSResource"
        values   = ["true"]
      }
    }
  }
}

###############################################################################
# KMS Key
###############################################################################

resource "aws_kms_key" "this" {
  description              = var.description
  key_usage                = var.key_usage
  customer_master_key_spec = var.customer_master_key_spec
  enable_key_rotation      = var.enable_key_rotation
  rotation_period_in_days  = var.enable_key_rotation ? var.rotation_period_in_days : null
  multi_region             = var.multi_region
  deletion_window_in_days  = var.deletion_window_in_days
  is_enabled               = true

  policy = var.key_policy != null ? var.key_policy : data.aws_iam_policy_document.key_policy[0].json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-${var.name}"
  })
}

###############################################################################
# KMS Alias
###############################################################################

resource "aws_kms_alias" "this" {
  name          = "alias/${local.name_prefix}-${var.name}"
  target_key_id = aws_kms_key.this.key_id
}

resource "aws_kms_alias" "additional" {
  for_each = toset(var.aliases)

  name          = "alias/${each.value}"
  target_key_id = aws_kms_key.this.key_id
}

###############################################################################
# KMS Grants
###############################################################################

resource "aws_kms_grant" "this" {
  for_each = var.grants

  name              = each.key
  key_id            = aws_kms_key.this.key_id
  grantee_principal = each.value.grantee_principal
  operations        = each.value.operations
  retiring_principal    = each.value.retiring_principal
  grant_creation_tokens = each.value.grant_creation_tokens

  dynamic "constraints" {
    for_each = each.value.constraints != null ? [each.value.constraints] : []
    content {
      encryption_context_equals = constraints.value.encryption_context_equals
      encryption_context_subset = constraints.value.encryption_context_subset
    }
  }
}
