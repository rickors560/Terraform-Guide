# -----------------------------------------------------------------------------
# KMS Component - Keys, Aliases, Policies, Rotation, Grants, Multi-Region
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment and configure for remote state:
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "components/kms/terraform.tfstate"
  #   region         = "ap-south-1"
  #   dynamodb_table = "terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "kms"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  partition   = data.aws_partition.current.partition
  region      = data.aws_region.current.name
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# General-Purpose KMS Key
# -----------------------------------------------------------------------------

resource "aws_kms_key" "general" {
  description             = "${local.name_prefix} general-purpose encryption key"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  rotation_period_in_days = var.rotation_period_in_days
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  multi_region            = var.enable_multi_region

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${local.name_prefix}-general-key-policy"
    Statement = [
      {
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowKeyAdministration"
        Effect = "Allow"
        Principal = {
          AWS = [for arn in var.key_admin_arns : arn]
        }
        Action = [
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
          "kms:RotateKeyOnDemand"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowKeyUsage"
        Effect = "Allow"
        Principal = {
          AWS = [for arn in var.key_user_arns : arn]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowAttachmentOfPersistentResources"
        Effect = "Allow"
        Principal = {
          AWS = [for arn in var.key_user_arns : arn]
        }
        Action = [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "kms:GrantIsForAWSResource" = "true"
          }
        }
      },
      {
        Sid    = "AllowAWSServicesAccess"
        Effect = "Allow"
        Principal = {
          Service = var.allowed_service_principals
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name    = "${local.name_prefix}-general"
    Purpose = "general-encryption"
  }
}

resource "aws_kms_alias" "general" {
  name          = "alias/${local.name_prefix}-general"
  target_key_id = aws_kms_key.general.key_id
}

# -----------------------------------------------------------------------------
# S3 Encryption Key
# -----------------------------------------------------------------------------

resource "aws_kms_key" "s3" {
  description             = "${local.name_prefix} S3 bucket encryption key"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  rotation_period_in_days = var.rotation_period_in_days
  is_enabled              = true
  multi_region            = var.enable_multi_region

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${local.name_prefix}-s3-key-policy"
    Statement = [
      {
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowS3ServiceAccess"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowKeyAdmins"
        Effect = "Allow"
        Principal = {
          AWS = [for arn in var.key_admin_arns : arn]
        }
        Action = [
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
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowKeyUsers"
        Effect = "Allow"
        Principal = {
          AWS = [for arn in var.key_user_arns : arn]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name    = "${local.name_prefix}-s3"
    Purpose = "s3-encryption"
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${local.name_prefix}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# -----------------------------------------------------------------------------
# RDS Encryption Key
# -----------------------------------------------------------------------------

resource "aws_kms_key" "rds" {
  description             = "${local.name_prefix} RDS database encryption key"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  rotation_period_in_days = var.rotation_period_in_days
  is_enabled              = true
  multi_region            = var.enable_multi_region

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${local.name_prefix}-rds-key-policy"
    Statement = [
      {
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowRDSServiceAccess"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowKeyAdmins"
        Effect = "Allow"
        Principal = {
          AWS = [for arn in var.key_admin_arns : arn]
        }
        Action = [
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
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name    = "${local.name_prefix}-rds"
    Purpose = "rds-encryption"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${local.name_prefix}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# -----------------------------------------------------------------------------
# EBS Encryption Key
# -----------------------------------------------------------------------------

resource "aws_kms_key" "ebs" {
  description             = "${local.name_prefix} EBS volume encryption key"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
  rotation_period_in_days = var.rotation_period_in_days
  is_enabled              = true
  multi_region            = false

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "${local.name_prefix}-ebs-key-policy"
    Statement = [
      {
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowEBSAccess"
        Effect = "Allow"
        Principal = {
          AWS = [for arn in var.key_user_arns : arn]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "ec2.${local.region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "${local.name_prefix}-ebs"
    Purpose = "ebs-encryption"
  }
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${local.name_prefix}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

# -----------------------------------------------------------------------------
# KMS Grants
# -----------------------------------------------------------------------------

resource "aws_kms_grant" "general" {
  for_each = var.kms_grants

  name              = each.key
  key_id            = aws_kms_key.general.key_id
  grantee_principal = each.value.grantee_principal
  operations        = each.value.operations

  dynamic "constraints" {
    for_each = each.value.encryption_context_subset != null ? [1] : []
    content {
      encryption_context_subset = each.value.encryption_context_subset
    }
  }
}
