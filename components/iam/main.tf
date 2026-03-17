# -----------------------------------------------------------------------------
# IAM Component - Roles, Policies, Users, Groups, Instance Profiles, OIDC
# -----------------------------------------------------------------------------
# This component creates a comprehensive IAM setup with least-privilege
# principles: admin/developer/readonly groups, service roles, instance
# profiles, and an OIDC provider for GitHub Actions.
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
  #   key            = "components/iam/terraform.tfstate"
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
      Component   = "iam"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition
  name_prefix = "${var.project_name}-${var.environment}"
}

# -----------------------------------------------------------------------------
# IAM Password Policy
# -----------------------------------------------------------------------------

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

# -----------------------------------------------------------------------------
# IAM Groups
# -----------------------------------------------------------------------------

resource "aws_iam_group" "admin" {
  name = "${local.name_prefix}-admins"
  path = "/${var.project_name}/"
}

resource "aws_iam_group" "developers" {
  name = "${local.name_prefix}-developers"
  path = "/${var.project_name}/"
}

resource "aws_iam_group" "readonly" {
  name = "${local.name_prefix}-readonly"
  path = "/${var.project_name}/"
}

# -----------------------------------------------------------------------------
# Group Policy Attachments
# -----------------------------------------------------------------------------

resource "aws_iam_group_policy_attachment" "admin_access" {
  group      = aws_iam_group.admin.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group_policy_attachment" "admin_mfa" {
  group      = aws_iam_group.admin.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

resource "aws_iam_group_policy_attachment" "developer_poweruser" {
  group      = aws_iam_group.developers.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/PowerUserAccess"
}

resource "aws_iam_group_policy_attachment" "developer_mfa" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

resource "aws_iam_group_policy_attachment" "developer_deny_iam_admin" {
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.deny_iam_admin.arn
}

resource "aws_iam_group_policy_attachment" "readonly_access" {
  group      = aws_iam_group.readonly.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_group_policy_attachment" "readonly_mfa" {
  group      = aws_iam_group.readonly.name
  policy_arn = aws_iam_policy.enforce_mfa.arn
}

# -----------------------------------------------------------------------------
# Custom IAM Policies
# -----------------------------------------------------------------------------

resource "aws_iam_policy" "enforce_mfa" {
  name        = "${local.name_prefix}-enforce-mfa"
  path        = "/${var.project_name}/"
  description = "Require MFA for all actions except managing own MFA device"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowViewAccountInfo"
        Effect = "Allow"
        Action = [
          "iam:GetAccountPasswordPolicy",
          "iam:ListVirtualMFADevices"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowManageOwnMFA"
        Effect = "Allow"
        Action = [
          "iam:CreateVirtualMFADevice",
          "iam:DeleteVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:ListMFADevices",
          "iam:ResyncMFADevice",
          "iam:DeactivateMFADevice"
        ]
        Resource = [
          "arn:${local.partition}:iam::${local.account_id}:mfa/$${aws:username}",
          "arn:${local.partition}:iam::${local.account_id}:user/$${aws:username}"
        ]
      },
      {
        Sid    = "AllowManageOwnPasswords"
        Effect = "Allow"
        Action = [
          "iam:ChangePassword",
          "iam:GetUser"
        ]
        Resource = "arn:${local.partition}:iam::${local.account_id}:user/$${aws:username}"
      },
      {
        Sid    = "DenyAllExceptListedIfNoMFA"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:GetUser",
          "iam:ListMFADevices",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken",
          "iam:ChangePassword",
          "iam:GetAccountPasswordPolicy"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-enforce-mfa"
  }
}

resource "aws_iam_policy" "deny_iam_admin" {
  name        = "${local.name_prefix}-deny-iam-admin"
  path        = "/${var.project_name}/"
  description = "Deny IAM administrative actions for non-admin users"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyIAMAdmin"
        Effect = "Deny"
        Action = [
          "iam:CreateUser",
          "iam:DeleteUser",
          "iam:CreateGroup",
          "iam:DeleteGroup",
          "iam:AttachGroupPolicy",
          "iam:DetachGroupPolicy",
          "iam:AttachUserPolicy",
          "iam:DetachUserPolicy",
          "iam:PutGroupPolicy",
          "iam:DeleteGroupPolicy",
          "iam:AddUserToGroup",
          "iam:RemoveUserFromGroup",
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-deny-iam-admin"
  }
}

resource "aws_iam_policy" "s3_read_only" {
  name        = "${local.name_prefix}-s3-readonly"
  path        = "/${var.project_name}/"
  description = "Least-privilege read-only access to specific S3 buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ]
        Resource = "arn:${local.partition}:s3:::*"
      },
      {
        Sid    = "ReadSpecificBucket"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:${local.partition}:s3:::${local.name_prefix}-*",
          "arn:${local.partition}:s3:::${local.name_prefix}-*/*"
        ]
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-s3-readonly"
  }
}

# -----------------------------------------------------------------------------
# IAM Users
# -----------------------------------------------------------------------------

resource "aws_iam_user" "users" {
  for_each = var.iam_users

  name          = each.key
  path          = "/${var.project_name}/"
  force_destroy = var.environment != "production"

  tags = {
    Name       = each.key
    Department = each.value.department
    Group      = each.value.group
  }
}

resource "aws_iam_user_group_membership" "users" {
  for_each = var.iam_users

  user   = aws_iam_user.users[each.key].name
  groups = [
    each.value.group == "admin"     ? aws_iam_group.admin.name :
    each.value.group == "developer" ? aws_iam_group.developers.name :
    aws_iam_group.readonly.name
  ]
}

# -----------------------------------------------------------------------------
# EC2 Instance Profile / Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ec2_instance" {
  name = "${local.name_prefix}-ec2-instance-role"
  path = "/${var.project_name}/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  max_session_duration = 3600

  tags = {
    Name = "${local.name_prefix}-ec2-instance-role"
  }
}

resource "aws_iam_role_policy" "ec2_instance_ssm" {
  name = "${local.name_prefix}-ec2-ssm-access"
  role = aws_iam_role.ec2_instance.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMCoreAccess"
        Effect = "Allow"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:${local.partition}:logs:*:${local.account_id}:log-group:/${var.project_name}/*"
      },
      {
        Sid    = "SSMParameterRead"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:${local.partition}:ssm:*:${local.account_id}:parameter/${var.project_name}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch_agent" {
  role       = aws_iam_role.ec2_instance.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "ec2_instance" {
  name = "${local.name_prefix}-ec2-instance-profile"
  path = "/${var.project_name}/"
  role = aws_iam_role.ec2_instance.name

  tags = {
    Name = "${local.name_prefix}-ec2-instance-profile"
  }
}

# -----------------------------------------------------------------------------
# Lambda Execution Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "lambda_execution" {
  name = "${local.name_prefix}-lambda-execution-role"
  path = "/${var.project_name}/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-lambda-execution-role"
  }
}

resource "aws_iam_role_policy" "lambda_execution" {
  name = "${local.name_prefix}-lambda-execution-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${local.partition}:logs:*:${local.account_id}:log-group:/aws/lambda/${local.name_prefix}-*:*"
      },
      {
        Sid    = "XRayTracing"
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Cross-Account Assume Role
# -----------------------------------------------------------------------------

resource "aws_iam_role" "cross_account" {
  count = length(var.trusted_account_ids) > 0 ? 1 : 0

  name = "${local.name_prefix}-cross-account-role"
  path = "/${var.project_name}/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CrossAccountAssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = [for id in var.trusted_account_ids : "arn:${local.partition}:iam::${id}:root"]
        }
        Action = "sts:AssumeRole"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent" = "true"
          }
          NumericLessThan = {
            "aws:MultiFactorAuthAge" = "3600"
          }
        }
      }
    ]
  })

  max_session_duration = 3600

  tags = {
    Name = "${local.name_prefix}-cross-account-role"
  }
}

resource "aws_iam_role_policy_attachment" "cross_account_readonly" {
  count = length(var.trusted_account_ids) > 0 ? 1 : 0

  role       = aws_iam_role.cross_account[0].name
  policy_arn = "arn:${local.partition}:iam::aws:policy/ReadOnlyAccess"
}

# -----------------------------------------------------------------------------
# OIDC Provider for GitHub Actions
# -----------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github_actions" {
  count = var.enable_github_oidc ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]

  tags = {
    Name = "${local.name_prefix}-github-oidc"
  }
}

resource "aws_iam_role" "github_actions" {
  count = var.enable_github_oidc ? 1 : 0

  name = "${local.name_prefix}-github-actions-role"
  path = "/${var.project_name}/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "GitHubActionsAssumeRole"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions[0].arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              for repo in var.github_repositories :
              "repo:${repo}:*"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-github-actions-role"
  }
}

resource "aws_iam_role_policy" "github_actions" {
  count = var.enable_github_oidc ? 1 : 0

  name = "${local.name_prefix}-github-actions-policy"
  role = aws_iam_role.github_actions[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3DeployAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:${local.partition}:s3:::${local.name_prefix}-*",
          "arn:${local.partition}:s3:::${local.name_prefix}-*/*"
        ]
      },
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:${local.partition}:s3:::${var.project_name}-terraform-state",
          "arn:${local.partition}:s3:::${var.project_name}-terraform-state/*"
        ]
      },
      {
        Sid    = "DynamoDBLockAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:${local.partition}:dynamodb:*:${local.account_id}:table/terraform-locks"
      }
    ]
  })
}
