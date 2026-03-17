# -----------------------------------------------------------------------------
# EFS Component - File System, Mount Targets, Access Points, Encryption
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
  #   key            = "components/efs/terraform.tfstate"
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
      Component   = "efs"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# KMS Key for EFS Encryption
# -----------------------------------------------------------------------------

resource "aws_kms_key" "efs" {
  description             = "${local.name_prefix} EFS encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = {
    Name = "${local.name_prefix}-efs-kms"
  }
}

resource "aws_kms_alias" "efs" {
  name          = "alias/${local.name_prefix}-efs"
  target_key_id = aws_kms_key.efs.key_id
}

# -----------------------------------------------------------------------------
# Security Group
# -----------------------------------------------------------------------------

resource "aws_security_group" "efs" {
  name        = "${local.name_prefix}-efs-sg"
  description = "Security group for EFS mount targets"
  vpc_id      = var.vpc_id

  ingress {
    description     = "NFS from allowed security groups"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  ingress {
    description = "NFS from allowed CIDRs"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-efs-sg"
  }
}

# -----------------------------------------------------------------------------
# EFS File System
# -----------------------------------------------------------------------------

resource "aws_efs_file_system" "main" {
  creation_token = "${local.name_prefix}-efs"
  encrypted      = true
  kms_key_id     = aws_kms_key.efs.arn

  performance_mode                = var.performance_mode
  throughput_mode                 = var.throughput_mode
  provisioned_throughput_in_mibps = var.throughput_mode == "provisioned" ? var.provisioned_throughput : null

  lifecycle_policy {
    transition_to_ia = var.transition_to_ia
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = {
    Name = "${local.name_prefix}-efs"
  }
}

# -----------------------------------------------------------------------------
# Backup Policy
# -----------------------------------------------------------------------------

resource "aws_efs_backup_policy" "main" {
  file_system_id = aws_efs_file_system.main.id

  backup_policy {
    status = var.enable_backup ? "ENABLED" : "DISABLED"
  }
}

# -----------------------------------------------------------------------------
# File System Policy
# -----------------------------------------------------------------------------

resource "aws_efs_file_system_policy" "main" {
  file_system_id = aws_efs_file_system.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceEncryptionInTransit"
        Effect = "Deny"
        Principal = {
          AWS = "*"
        }
        Action   = "*"
        Resource = aws_efs_file_system.main.arn
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "EnforceRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = aws_efs_file_system.main.arn
        Condition = {
          Bool = {
            "elasticfilesystem:AccessedViaMountTarget" = "true"
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Mount Targets
# -----------------------------------------------------------------------------

resource "aws_efs_mount_target" "main" {
  for_each = toset(var.subnet_ids)

  file_system_id  = aws_efs_file_system.main.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

# -----------------------------------------------------------------------------
# Access Points
# -----------------------------------------------------------------------------

resource "aws_efs_access_point" "app" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/app"

    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name    = "${local.name_prefix}-efs-ap-app"
    Purpose = "application-data"
  }
}

resource "aws_efs_access_point" "logs" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid = 1000
    uid = 1000
  }

  root_directory {
    path = "/logs"

    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }

  tags = {
    Name    = "${local.name_prefix}-efs-ap-logs"
    Purpose = "application-logs"
  }
}

resource "aws_efs_access_point" "shared" {
  file_system_id = aws_efs_file_system.main.id

  posix_user {
    gid            = 1000
    uid            = 1000
    secondary_gids = [1001]
  }

  root_directory {
    path = "/shared"

    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "775"
    }
  }

  tags = {
    Name    = "${local.name_prefix}-efs-ap-shared"
    Purpose = "shared-data"
  }
}
