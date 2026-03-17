################################################################################
# Data Sources
################################################################################

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  name_prefix = "${var.project_name}-global"
  account_id  = data.aws_caller_identity.current.account_id
  partition   = data.aws_partition.current.partition

  trust_policy_principals = length(var.trusted_account_ids) > 0 ? var.trusted_account_ids : [local.account_id]

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = "global"
      ManagedBy   = "terraform"
      Team        = var.team
      CostCenter  = var.cost_center
      Repository  = var.repository
    },
    var.additional_tags,
  )
}

################################################################################
# Route53 Hosted Zone
################################################################################

resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Managed by Terraform - ${var.project_name} primary hosted zone"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-zone"
  })
}

################################################################################
# IAM Role: Admin
################################################################################

data "aws_iam_policy_document" "admin_assume_role" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [for id in local.trust_policy_principals : "arn:${local.partition}:iam::${id}:root"]
    }

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role" "admin" {
  name                 = "${local.name_prefix}-admin"
  assume_role_policy   = data.aws_iam_policy_document.admin_assume_role.json
  max_session_duration = var.admin_max_session_duration
  description          = "Admin role for ${var.project_name} - full access with MFA requirement"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-admin"
    Role = "admin"
  })
}

resource "aws_iam_role_policy_attachment" "admin_administrator_access" {
  role       = aws_iam_role.admin.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AdministratorAccess"
}

################################################################################
# IAM Role: Developer
################################################################################

data "aws_iam_policy_document" "developer_assume_role" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [for id in local.trust_policy_principals : "arn:${local.partition}:iam::${id}:root"]
    }

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }
  }
}

resource "aws_iam_role" "developer" {
  name                 = "${local.name_prefix}-developer"
  assume_role_policy   = data.aws_iam_policy_document.developer_assume_role.json
  max_session_duration = var.developer_max_session_duration
  description          = "Developer role for ${var.project_name} - power user access with MFA requirement"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-developer"
    Role = "developer"
  })
}

resource "aws_iam_role_policy_attachment" "developer_power_user" {
  role       = aws_iam_role.developer.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/PowerUserAccess"
}

data "aws_iam_policy_document" "developer_deny_iam_dangerous" {
  statement {
    sid    = "DenyDangerousIAMActions"
    effect = "Deny"
    actions = [
      "iam:CreateUser",
      "iam:DeleteUser",
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:AttachUserPolicy",
      "iam:DetachUserPolicy",
      "iam:PutUserPolicy",
      "iam:DeleteUserPolicy",
      "iam:CreateGroup",
      "iam:DeleteGroup",
      "organizations:*",
      "account:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "developer_deny_dangerous" {
  name        = "${local.name_prefix}-developer-deny-dangerous"
  description = "Deny dangerous IAM and account operations for developers"
  policy      = data.aws_iam_policy_document.developer_deny_iam_dangerous.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-developer-deny-dangerous"
  })
}

resource "aws_iam_role_policy_attachment" "developer_deny_dangerous" {
  role       = aws_iam_role.developer.name
  policy_arn = aws_iam_policy.developer_deny_dangerous.arn
}

################################################################################
# IAM Role: Readonly
################################################################################

data "aws_iam_policy_document" "readonly_assume_role" {
  statement {
    sid     = "AllowAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [for id in local.trust_policy_principals : "arn:${local.partition}:iam::${id}:root"]
    }
  }
}

resource "aws_iam_role" "readonly" {
  name                 = "${local.name_prefix}-readonly"
  assume_role_policy   = data.aws_iam_policy_document.readonly_assume_role.json
  max_session_duration = var.readonly_max_session_duration
  description          = "Readonly role for ${var.project_name} - view-only access"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-readonly"
    Role = "readonly"
  })
}

resource "aws_iam_role_policy_attachment" "readonly_view_only" {
  role       = aws_iam_role.readonly.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/ViewOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "readonly_security_audit" {
  role       = aws_iam_role.readonly.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/SecurityAudit"
}

################################################################################
# Account-Level Settings: S3 Public Access Block
################################################################################

resource "aws_s3_account_public_access_block" "account" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################################################################
# Account-Level Settings: EBS Default Encryption
################################################################################

resource "aws_ebs_encryption_by_default" "enabled" {
  enabled = true
}

################################################################################
# Account-Level Settings: IAM Account Password Policy
################################################################################

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_numbers                = true
  require_uppercase_characters   = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 24
  hard_expiry                    = false
}
