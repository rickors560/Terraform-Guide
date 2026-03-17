# -----------------------------------------------------------------------------
# Secrets Manager Component - Secrets, Rotation, KMS, Resource Policy
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
  #   key            = "components/secrets-manager/terraform.tfstate"
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
      Component   = "secrets-manager"
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
# KMS Key for Secrets Encryption
# -----------------------------------------------------------------------------

resource "aws_kms_key" "secrets" {
  description             = "${local.name_prefix} Secrets Manager encryption key"
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
        Sid    = "AllowSecretsManagerAccess"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
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
    Name = "${local.name_prefix}-secrets-kms"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.name_prefix}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# -----------------------------------------------------------------------------
# Database Credentials Secret
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "database" {
  name                    = "${local.name_prefix}/database/credentials"
  description             = "Database credentials for ${local.name_prefix}"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name    = "${local.name_prefix}-db-credentials"
    Purpose = "database"
  }
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = var.db_engine
    host     = var.db_host
    port     = var.db_port
    dbname   = var.db_name
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# -----------------------------------------------------------------------------
# API Key Secret
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "api_key" {
  name                    = "${local.name_prefix}/api/key"
  description             = "API key for ${local.name_prefix} application"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name    = "${local.name_prefix}-api-key"
    Purpose = "api-authentication"
  }
}

resource "aws_secretsmanager_secret_version" "api_key" {
  secret_id     = aws_secretsmanager_secret.api_key.id
  secret_string = jsonencode({
    api_key    = var.api_key
    api_secret = var.api_secret
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# -----------------------------------------------------------------------------
# Application Configuration Secret
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "app_config" {
  name                    = "${local.name_prefix}/app/config"
  description             = "Application configuration secrets for ${local.name_prefix}"
  kms_key_id              = aws_kms_key.secrets.arn
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name    = "${local.name_prefix}-app-config"
    Purpose = "application-config"
  }
}

resource "aws_secretsmanager_secret_version" "app_config" {
  secret_id = aws_secretsmanager_secret.app_config.id
  secret_string = jsonencode({
    jwt_secret     = var.jwt_secret
    encryption_key = var.encryption_key
    session_secret = var.session_secret
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# -----------------------------------------------------------------------------
# Rotation Configuration (Lambda-based)
# -----------------------------------------------------------------------------

resource "aws_iam_role" "rotation_lambda" {
  count = var.enable_rotation ? 1 : 0

  name = "${local.name_prefix}-secrets-rotation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-secrets-rotation-role"
  }
}

resource "aws_iam_role_policy" "rotation_lambda" {
  count = var.enable_rotation ? 1 : 0

  name = "${local.name_prefix}-secrets-rotation-policy"
  role = aws_iam_role.rotation_lambda[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage"
        ]
        Resource = aws_secretsmanager_secret.database.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetRandomPassword"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.secrets.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${local.partition}:logs:*:${local.account_id}:log-group:/aws/lambda/${local.name_prefix}-*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rotation_lambda_vpc" {
  count = var.enable_rotation ? 1 : 0

  role       = aws_iam_role.rotation_lambda[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# -----------------------------------------------------------------------------
# Resource Policy for Cross-Account Access
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret_policy" "database" {
  secret_arn = aws_secretsmanager_secret.database.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCurrentAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:${local.partition}:iam::${local.account_id}:root"
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyNonEncryptedAccess"
        Effect = "Deny"
        Principal = "*"
        Action   = "secretsmanager:*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalAccount" = local.account_id
          }
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AllowCrossAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = [for id in var.cross_account_ids : "arn:${local.partition}:iam::${id}:root"]
        }
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalTag/Environment" = var.environment
          }
        }
      }
    ]
  })
}
