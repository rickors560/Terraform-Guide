###############################################################################
# ECR Component — Repository with Lifecycle, Scanning, Encryption
###############################################################################

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "components/ecr/terraform.tfstate"
  #   region         = "ap-south-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Component   = "ecr"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# ECR Repository
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "main" {
  name                 = "${var.project_name}/${var.repository_name}"
  image_tag_mutability = var.image_tag_mutability
  force_delete         = var.environment != "prod"

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.kms_key_arn != "" ? "KMS" : "AES256"
    kms_key         = var.kms_key_arn != "" ? var.kms_key_arn : null
  }

  tags = {
    Name = "${var.project_name}-${var.repository_name}"
  }
}

# -----------------------------------------------------------------------------
# Lifecycle Policy
# -----------------------------------------------------------------------------

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_tagged_images} tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "release", "prod"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_tagged_images
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last ${var.max_dev_images} dev/staging tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev", "staging", "feature"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_dev_images
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 10
        description  = "Remove untagged images after ${var.untagged_image_expiry_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_expiry_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Repository Policy (same-account + optional cross-account)
# -----------------------------------------------------------------------------

resource "aws_ecr_repository_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid       = "AllowAccountAccess"
          Effect    = "Allow"
          Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:DescribeRepositories",
            "ecr:GetRepositoryPolicy",
            "ecr:ListImages",
            "ecr:DescribeImages"
          ]
        }
      ],
      [
        for account_id in var.cross_account_pull_ids : {
          Sid       = "AllowCrossAccountPull-${account_id}"
          Effect    = "Allow"
          Principal = { AWS = "arn:aws:iam::${account_id}:root" }
          Action = [
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:DescribeImages",
            "ecr:ListImages"
          ]
        }
      ]
    )
  })
}

# -----------------------------------------------------------------------------
# Pull-Through Cache Rule (optional — for upstream public registries)
# -----------------------------------------------------------------------------

resource "aws_ecr_pull_through_cache_rule" "ecr_public" {
  count = var.enable_pull_through_cache ? 1 : 0

  ecr_repository_prefix = "ecr-public"
  upstream_registry_url = "public.ecr.aws"
}

# -----------------------------------------------------------------------------
# Registry Scanning Configuration
# -----------------------------------------------------------------------------

resource "aws_ecr_registry_scanning_configuration" "main" {
  scan_type = var.enhanced_scanning ? "ENHANCED" : "BASIC"

  dynamic "rule" {
    for_each = var.enhanced_scanning ? [1] : []
    content {
      scan_frequency = "CONTINUOUS_SCAN"
      repository_filter {
        filter      = "${var.project_name}/*"
        filter_type = "WILDCARD"
      }
    }
  }
}
