# -----------------------------------------------------------------------------
# Cognito Component - User Pool, App Client, Domain, Groups, MFA, Identity Pool
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
  #   key            = "components/cognito/terraform.tfstate"
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
      Component   = "cognito"
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
# Cognito User Pool
# -----------------------------------------------------------------------------

resource "aws_cognito_user_pool" "main" {
  name = "${local.name_prefix}-user-pool"

  # Sign-in configuration
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Username configuration
  username_configuration {
    case_sensitive = false
  }

  # Password policy
  password_policy {
    minimum_length                   = var.password_minimum_length
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  # MFA configuration
  mfa_configuration = var.mfa_configuration

  software_token_mfa_configuration {
    enabled = true
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # User attribute schema
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    mutable                  = true
    required                 = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 5
      max_length = 254
    }
  }

  schema {
    name                     = "name"
    attribute_data_type      = "String"
    mutable                  = true
    required                 = true
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    name                     = "department"
    attribute_data_type      = "String"
    mutable                  = true
    required                 = false
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 0
      max_length = 100
    }
  }

  schema {
    name                     = "role"
    attribute_data_type      = "String"
    mutable                  = true
    required                 = false
    developer_only_attribute = false

    string_attribute_constraints {
      min_length = 0
      max_length = 50
    }
  }

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Verification message
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "${var.project_name} - Verify your email"
    email_message        = "Your verification code is: {####}"
  }

  # Advanced security
  user_pool_add_ons {
    advanced_security_mode = var.advanced_security_mode
  }

  # Device tracking
  device_configuration {
    challenge_required_on_new_device      = true
    device_only_remembered_on_user_prompt = true
  }

  # Deletion protection
  deletion_protection = var.environment == "production" ? "ACTIVE" : "INACTIVE"

  # Lambda triggers
  dynamic "lambda_config" {
    for_each = var.pre_sign_up_lambda_arn != "" || var.post_confirmation_lambda_arn != "" || var.pre_token_generation_lambda_arn != "" ? [1] : []
    content {
      pre_sign_up                    = var.pre_sign_up_lambda_arn != "" ? var.pre_sign_up_lambda_arn : null
      post_confirmation              = var.post_confirmation_lambda_arn != "" ? var.post_confirmation_lambda_arn : null
      pre_token_generation           = var.pre_token_generation_lambda_arn != "" ? var.pre_token_generation_lambda_arn : null
    }
  }

  tags = {
    Name = "${local.name_prefix}-user-pool"
  }
}

# -----------------------------------------------------------------------------
# User Pool Domain
# -----------------------------------------------------------------------------

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${local.name_prefix}-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}

# -----------------------------------------------------------------------------
# User Pool App Clients
# -----------------------------------------------------------------------------

resource "aws_cognito_user_pool_client" "web" {
  name         = "${local.name_prefix}-web-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret                      = false
  prevent_user_existence_errors        = "ENABLED"
  enable_token_revocation              = true
  allowed_oauth_flows_user_pool_client = true

  allowed_oauth_flows  = ["code"]
  allowed_oauth_scopes = ["email", "openid", "profile"]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  supported_identity_providers = ["COGNITO"]

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  access_token_validity  = var.access_token_validity_hours
  id_token_validity      = var.id_token_validity_hours
  refresh_token_validity = var.refresh_token_validity_days

  read_attributes  = ["email", "name", "custom:department", "custom:role"]
  write_attributes = ["email", "name", "custom:department", "custom:role"]
}

resource "aws_cognito_user_pool_client" "server" {
  name         = "${local.name_prefix}-server-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret                      = true
  prevent_user_existence_errors        = "ENABLED"
  enable_token_revocation              = true
  allowed_oauth_flows_user_pool_client = true

  allowed_oauth_flows  = ["client_credentials"]
  allowed_oauth_scopes = aws_cognito_resource_server.api.scope_identifiers

  supported_identity_providers = ["COGNITO"]

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  access_token_validity  = 1
  refresh_token_validity = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}

# -----------------------------------------------------------------------------
# Resource Server
# -----------------------------------------------------------------------------

resource "aws_cognito_resource_server" "api" {
  identifier   = "https://api.${var.project_name}.${var.environment}"
  name         = "${local.name_prefix}-api"
  user_pool_id = aws_cognito_user_pool.main.id

  scope {
    scope_name        = "read"
    scope_description = "Read access to the API"
  }

  scope {
    scope_name        = "write"
    scope_description = "Write access to the API"
  }

  scope {
    scope_name        = "admin"
    scope_description = "Admin access to the API"
  }
}

# -----------------------------------------------------------------------------
# User Pool Groups
# -----------------------------------------------------------------------------

resource "aws_cognito_user_group" "admin" {
  name         = "admin"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Administrator group with full access"
  precedence   = 1
  role_arn     = aws_iam_role.cognito_admin.arn
}

resource "aws_cognito_user_group" "editor" {
  name         = "editor"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Editor group with read/write access"
  precedence   = 10
  role_arn     = aws_iam_role.cognito_editor.arn
}

resource "aws_cognito_user_group" "viewer" {
  name         = "viewer"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Viewer group with read-only access"
  precedence   = 100
  role_arn     = aws_iam_role.cognito_viewer.arn
}

# -----------------------------------------------------------------------------
# IAM Roles for Cognito Groups
# -----------------------------------------------------------------------------

resource "aws_iam_role" "cognito_admin" {
  name = "${local.name_prefix}-cognito-admin-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-cognito-admin-role"
  }
}

resource "aws_iam_role" "cognito_editor" {
  name = "${local.name_prefix}-cognito-editor-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-cognito-editor-role"
  }
}

resource "aws_iam_role" "cognito_viewer" {
  name = "${local.name_prefix}-cognito-viewer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-cognito-viewer-role"
  }
}

# -----------------------------------------------------------------------------
# Cognito Identity Pool
# -----------------------------------------------------------------------------

resource "aws_cognito_identity_pool" "main" {
  identity_pool_name               = "${local.name_prefix}-identity-pool"
  allow_unauthenticated_identities = false
  allow_classic_flow               = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.web.id
    provider_name           = aws_cognito_user_pool.main.endpoint
    server_side_token_check = true
  }

  tags = {
    Name = "${local.name_prefix}-identity-pool"
  }
}

# Authenticated role for identity pool
resource "aws_iam_role" "cognito_authenticated" {
  name = "${local.name_prefix}-cognito-authenticated"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "cognito-identity.amazonaws.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "cognito-identity.amazonaws.com:aud" = aws_cognito_identity_pool.main.id
          }
          "ForAnyValue:StringLike" = {
            "cognito-identity.amazonaws.com:amr" = "authenticated"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-cognito-authenticated"
  }
}

resource "aws_iam_role_policy" "cognito_authenticated" {
  name = "${local.name_prefix}-cognito-authenticated-policy"
  role = aws_iam_role.cognito_authenticated.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cognito-sync:*",
          "cognito-identity:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:${local.partition}:s3:::${local.name_prefix}-user-data/$${cognito-identity.amazonaws.com:sub}/*"
      }
    ]
  })
}

resource "aws_cognito_identity_pool_roles_attachment" "main" {
  identity_pool_id = aws_cognito_identity_pool.main.id

  roles = {
    "authenticated" = aws_iam_role.cognito_authenticated.arn
  }

  role_mapping {
    identity_provider         = "${aws_cognito_user_pool.main.endpoint}:${aws_cognito_user_pool_client.web.id}"
    ambiguous_role_resolution = "AuthenticatedRole"
    type                      = "Token"
  }
}
