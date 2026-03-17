# -----------------------------------------------------------------------------
# SSM Parameter Store - String, StringList, SecureString, Hierarchical Paths
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
  #   key            = "components/ssm-parameter-store/terraform.tfstate"
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
      Component   = "ssm-parameter-store"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  partition   = data.aws_partition.current.partition
  name_prefix = "${var.project_name}-${var.environment}"
  param_prefix = "/${var.project_name}/${var.environment}"
}

# -----------------------------------------------------------------------------
# KMS Key for SecureString Parameters
# -----------------------------------------------------------------------------

resource "aws_kms_key" "ssm" {
  description             = "${local.name_prefix} SSM Parameter Store encryption key"
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
        Sid    = "AllowSSMAccess"
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-ssm-kms"
  }
}

resource "aws_kms_alias" "ssm" {
  name          = "alias/${local.name_prefix}-ssm"
  target_key_id = aws_kms_key.ssm.key_id
}

# -----------------------------------------------------------------------------
# Application Configuration Parameters (String type)
# -----------------------------------------------------------------------------

resource "aws_ssm_parameter" "app_name" {
  name        = "${local.param_prefix}/app/name"
  description = "Application name"
  type        = "String"
  value       = var.project_name
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-app-name"
    Category = "config"
  }
}

resource "aws_ssm_parameter" "app_environment" {
  name        = "${local.param_prefix}/app/environment"
  description = "Application environment"
  type        = "String"
  value       = var.environment
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-app-environment"
    Category = "config"
  }
}

resource "aws_ssm_parameter" "app_log_level" {
  name        = "${local.param_prefix}/app/log-level"
  description = "Application log level"
  type        = "String"
  value       = var.log_level
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-app-log-level"
    Category = "config"
  }
}

resource "aws_ssm_parameter" "app_port" {
  name        = "${local.param_prefix}/app/port"
  description = "Application listening port"
  type        = "String"
  value       = tostring(var.app_port)
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-app-port"
    Category = "config"
  }
}

resource "aws_ssm_parameter" "app_max_connections" {
  name        = "${local.param_prefix}/app/max-connections"
  description = "Maximum number of concurrent connections"
  type        = "String"
  value       = tostring(var.max_connections)
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-app-max-connections"
    Category = "config"
  }
}

# -----------------------------------------------------------------------------
# Feature Flags (StringList type)
# -----------------------------------------------------------------------------

resource "aws_ssm_parameter" "feature_flags" {
  name        = "${local.param_prefix}/app/feature-flags"
  description = "Comma-separated list of enabled feature flags"
  type        = "StringList"
  value       = join(",", var.feature_flags)
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-feature-flags"
    Category = "config"
  }
}

resource "aws_ssm_parameter" "allowed_origins" {
  name        = "${local.param_prefix}/app/allowed-origins"
  description = "Comma-separated list of allowed CORS origins"
  type        = "StringList"
  value       = join(",", var.allowed_origins)
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-allowed-origins"
    Category = "config"
  }
}

# -----------------------------------------------------------------------------
# Database Configuration Parameters (SecureString type)
# -----------------------------------------------------------------------------

resource "aws_ssm_parameter" "db_host" {
  name        = "${local.param_prefix}/database/host"
  description = "Database host endpoint"
  type        = "String"
  value       = var.db_host
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-db-host"
    Category = "database"
  }
}

resource "aws_ssm_parameter" "db_port" {
  name        = "${local.param_prefix}/database/port"
  description = "Database port"
  type        = "String"
  value       = tostring(var.db_port)
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-db-port"
    Category = "database"
  }
}

resource "aws_ssm_parameter" "db_name" {
  name        = "${local.param_prefix}/database/name"
  description = "Database name"
  type        = "String"
  value       = var.db_name
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-db-name"
    Category = "database"
  }
}

resource "aws_ssm_parameter" "db_username" {
  name        = "${local.param_prefix}/database/username"
  description = "Database master username"
  type        = "SecureString"
  value       = var.db_username
  key_id      = aws_kms_key.ssm.arn
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-db-username"
    Category = "database"
  }

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "db_password" {
  name        = "${local.param_prefix}/database/password"
  description = "Database master password"
  type        = "SecureString"
  value       = var.db_password
  key_id      = aws_kms_key.ssm.arn
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-db-password"
    Category = "database"
  }

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "db_connection_string" {
  name        = "${local.param_prefix}/database/connection-string"
  description = "Full database connection string"
  type        = "SecureString"
  value       = "postgresql://${var.db_username}:${var.db_password}@${var.db_host}:${var.db_port}/${var.db_name}"
  key_id      = aws_kms_key.ssm.arn
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-db-connection-string"
    Category = "database"
  }

  lifecycle {
    ignore_changes = [value]
  }
}

# -----------------------------------------------------------------------------
# Cache Configuration Parameters
# -----------------------------------------------------------------------------

resource "aws_ssm_parameter" "cache_host" {
  name        = "${local.param_prefix}/cache/host"
  description = "Cache cluster endpoint"
  type        = "String"
  value       = var.cache_host
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-cache-host"
    Category = "cache"
  }
}

resource "aws_ssm_parameter" "cache_port" {
  name        = "${local.param_prefix}/cache/port"
  description = "Cache port"
  type        = "String"
  value       = tostring(var.cache_port)
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-cache-port"
    Category = "cache"
  }
}

resource "aws_ssm_parameter" "cache_auth_token" {
  name        = "${local.param_prefix}/cache/auth-token"
  description = "Cache authentication token"
  type        = "SecureString"
  value       = var.cache_auth_token
  key_id      = aws_kms_key.ssm.arn
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-cache-auth-token"
    Category = "cache"
  }

  lifecycle {
    ignore_changes = [value]
  }
}

# -----------------------------------------------------------------------------
# External Service Configuration
# -----------------------------------------------------------------------------

resource "aws_ssm_parameter" "api_key" {
  name        = "${local.param_prefix}/external/api-key"
  description = "External API key"
  type        = "SecureString"
  value       = var.external_api_key
  key_id      = aws_kms_key.ssm.arn
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-external-api-key"
    Category = "external"
  }

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "api_base_url" {
  name        = "${local.param_prefix}/external/api-base-url"
  description = "External API base URL"
  type        = "String"
  value       = var.external_api_base_url
  tier        = "Standard"

  tags = {
    Name     = "${local.name_prefix}-external-api-url"
    Category = "external"
  }
}

# -----------------------------------------------------------------------------
# IAM Policy for Parameter Store Access
# -----------------------------------------------------------------------------

resource "aws_iam_policy" "ssm_read_all" {
  name        = "${local.name_prefix}-ssm-read-all"
  description = "Read access to all SSM parameters under ${local.param_prefix}/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowParameterRead"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:GetParameterHistory"
        ]
        Resource = "arn:${local.partition}:ssm:*:${local.account_id}:parameter${local.param_prefix}/*"
      },
      {
        Sid    = "AllowDescribeParameters"
        Effect = "Allow"
        Action = [
          "ssm:DescribeParameters"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowKMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.ssm.arn
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-ssm-read-all"
  }
}

resource "aws_iam_policy" "ssm_read_config_only" {
  name        = "${local.name_prefix}-ssm-read-config"
  description = "Read access to non-sensitive SSM parameters (no SecureString decryption)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowParameterRead"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = [
          "arn:${local.partition}:ssm:*:${local.account_id}:parameter${local.param_prefix}/app/*",
          "arn:${local.partition}:ssm:*:${local.account_id}:parameter${local.param_prefix}/external/api-base-url"
        ]
      },
      {
        Sid    = "AllowDescribeParameters"
        Effect = "Allow"
        Action = "ssm:DescribeParameters"
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-ssm-read-config"
  }
}
