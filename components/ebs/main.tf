# -----------------------------------------------------------------------------
# EBS Component - Volume, Encryption, Snapshot, DLM Lifecycle, Attachment
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
  #   key            = "components/ebs/terraform.tfstate"
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
      Component   = "ebs"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  partition   = data.aws_partition.current.partition
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# KMS Key for EBS Encryption
# -----------------------------------------------------------------------------

resource "aws_kms_key" "ebs" {
  description             = "${local.name_prefix} EBS volume encryption key"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
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
        Sid    = "AllowEBSServiceAccess"
        Effect = "Allow"
        Principal = {
          AWS = "*"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = local.account_id
            "kms:ViaService"    = "ec2.${var.region}.amazonaws.com"
          }
        }
      },
      {
        Sid    = "AllowDLMAccess"
        Effect = "Allow"
        Principal = {
          Service = "dlm.amazonaws.com"
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
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-ebs-kms"
  }
}

resource "aws_kms_alias" "ebs" {
  name          = "alias/${local.name_prefix}-ebs"
  target_key_id = aws_kms_key.ebs.key_id
}

# -----------------------------------------------------------------------------
# EBS Volume - Application Data
# -----------------------------------------------------------------------------

resource "aws_ebs_volume" "app_data" {
  availability_zone = var.availability_zone
  size              = var.app_data_volume_size
  type              = var.app_data_volume_type
  iops              = contains(["io1", "io2", "gp3"], var.app_data_volume_type) ? var.app_data_volume_iops : null
  throughput         = var.app_data_volume_type == "gp3" ? var.app_data_volume_throughput : null
  encrypted         = true
  kms_key_id        = aws_kms_key.ebs.arn

  tags = {
    Name    = "${local.name_prefix}-app-data"
    Purpose = "application-data"
    Backup  = "true"
  }
}

# -----------------------------------------------------------------------------
# EBS Volume - Logs
# -----------------------------------------------------------------------------

resource "aws_ebs_volume" "logs" {
  availability_zone = var.availability_zone
  size              = var.logs_volume_size
  type              = "gp3"
  throughput         = 125
  iops              = 3000
  encrypted         = true
  kms_key_id        = aws_kms_key.ebs.arn

  tags = {
    Name    = "${local.name_prefix}-logs"
    Purpose = "logs"
    Backup  = "true"
  }
}

# -----------------------------------------------------------------------------
# Volume Attachments
# -----------------------------------------------------------------------------

resource "aws_volume_attachment" "app_data" {
  count = var.ec2_instance_id != "" ? 1 : 0

  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.app_data.id
  instance_id = var.ec2_instance_id

  stop_instance_before_detaching = true
}

resource "aws_volume_attachment" "logs" {
  count = var.ec2_instance_id != "" ? 1 : 0

  device_name = "/dev/xvdg"
  volume_id   = aws_ebs_volume.logs.id
  instance_id = var.ec2_instance_id

  stop_instance_before_detaching = true
}

# -----------------------------------------------------------------------------
# EBS Snapshot (initial)
# -----------------------------------------------------------------------------

resource "aws_ebs_snapshot" "app_data_initial" {
  volume_id   = aws_ebs_volume.app_data.id
  description = "Initial snapshot of ${local.name_prefix} app data volume"

  tags = {
    Name    = "${local.name_prefix}-app-data-initial"
    Purpose = "initial-snapshot"
  }
}

# -----------------------------------------------------------------------------
# DLM Lifecycle Policy
# -----------------------------------------------------------------------------

resource "aws_iam_role" "dlm" {
  name = "${local.name_prefix}-dlm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "dlm.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-dlm-role"
  }
}

resource "aws_iam_role_policy" "dlm" {
  name = "${local.name_prefix}-dlm-policy"
  role = aws_iam_role.dlm.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:CreateSnapshots",
          "ec2:DeleteSnapshot",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:EnableFastSnapshotRestores",
          "ec2:DisableFastSnapshotRestores"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "ec2:CreateTags"
        Resource = "arn:${local.partition}:ec2:*::snapshot/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = aws_kms_key.ebs.arn
      }
    ]
  })
}

resource "aws_dlm_lifecycle_policy" "ebs_snapshots" {
  description        = "DLM lifecycle policy for ${local.name_prefix} EBS volumes"
  execution_role_arn = aws_iam_role.dlm.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "daily-snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = [var.snapshot_time]
      }

      retain_rule {
        count = var.snapshot_retain_count
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
        Project         = var.project_name
        Environment     = var.environment
      }

      copy_tags = true
    }

    schedule {
      name = "weekly-snapshots"

      create_rule {
        cron_expression = "cron(0 ${replace(var.snapshot_time, ":", " ")} ? * SUN *)"
      }

      retain_rule {
        count = var.weekly_snapshot_retain_count
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
        SnapshotType    = "weekly"
        Project         = var.project_name
        Environment     = var.environment
      }

      copy_tags = true
    }

    target_tags = {
      Backup = "true"
    }
  }

  tags = {
    Name = "${local.name_prefix}-dlm-policy"
  }
}

# -----------------------------------------------------------------------------
# Enable EBS Encryption by Default
# -----------------------------------------------------------------------------

resource "aws_ebs_encryption_by_default" "enabled" {
  enabled = true
}

resource "aws_ebs_default_kms_key" "default" {
  key_arn = aws_kms_key.ebs.arn
}
