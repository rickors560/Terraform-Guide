################################################################################
# Artifact S3 Bucket
################################################################################

resource "aws_s3_bucket" "artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket        = local.artifact_bucket_name
  force_destroy = true

  tags = merge(local.common_tags, {
    Name = local.artifact_bucket_name
  })
}

resource "aws_s3_bucket_versioning" "artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.artifact_bucket_kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.artifact_bucket_kms_key_arn
    }
    bucket_key_enabled = var.artifact_bucket_kms_key_arn != null
  }
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  count = var.create_artifact_bucket ? 1 : 0

  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    id     = "expire-old-artifacts"
    status = "Enabled"

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

################################################################################
# IAM Role for CodePipeline
################################################################################

resource "aws_iam_role" "codepipeline" {
  count = var.create_iam_role ? 1 : 0

  name = "${local.name_prefix}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCodePipelineAssume"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "codepipeline" {
  count = var.create_iam_role ? 1 : 0

  name = "${local.name_prefix}-codepipeline-policy"
  role = aws_iam_role.codepipeline[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ArtifactAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketVersioning",
          "s3:PutObjectAcl",
          "s3:PutObject"
        ]
        Resource = var.create_artifact_bucket ? [
          aws_s3_bucket.artifacts[0].arn,
          "${aws_s3_bucket.artifacts[0].arn}/*"
        ] : [
          "arn:${data.aws_partition.current.partition}:s3:::${var.artifact_bucket_name}",
          "arn:${data.aws_partition.current.partition}:s3:::${var.artifact_bucket_name}/*"
        ]
      },
      {
        Sid    = "CodeStarConnectionAccess"
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection"
        ]
        Resource = "*"
      },
      {
        Sid    = "CodeBuildAccess"
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild",
          "codebuild:StopBuild"
        ]
        Resource = "*"
      },
      {
        Sid    = "CodeDeployAccess"
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetApplication",
          "codedeploy:GetApplicationRevision",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECSAccess"
        Effect = "Allow"
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks",
          "ecs:ListTasks",
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudFormationAccess"
        Effect = "Allow"
        Action = [
          "cloudformation:CreateStack",
          "cloudformation:DeleteStack",
          "cloudformation:DescribeStacks",
          "cloudformation:UpdateStack",
          "cloudformation:CreateChangeSet",
          "cloudformation:DeleteChangeSet",
          "cloudformation:DescribeChangeSet",
          "cloudformation:ExecuteChangeSet",
          "cloudformation:SetStackPolicy",
          "cloudformation:ValidateTemplate"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMPassRole"
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = "*"
        Condition = {
          StringEqualsIfExists = {
            "iam:PassedToService" = [
              "cloudformation.amazonaws.com",
              "ecs-tasks.amazonaws.com"
            ]
          }
        }
      },
      {
        Sid    = "CodeCommitAccess"
        Effect = "Allow"
        Action = [
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:UploadArchive",
          "codecommit:GetUploadArchiveStatus",
          "codecommit:CancelUploadArchive"
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = var.create_iam_role ? toset(var.additional_iam_policy_arns) : toset([])

  role       = aws_iam_role.codepipeline[0].name
  policy_arn = each.value
}

################################################################################
# CodePipeline
################################################################################

resource "aws_codepipeline" "this" {
  name           = local.pipeline_name
  role_arn       = var.create_iam_role ? aws_iam_role.codepipeline[0].arn : var.existing_role_arn
  pipeline_type  = var.pipeline_type
  execution_mode = var.execution_mode

  artifact_store {
    location = var.create_artifact_bucket ? aws_s3_bucket.artifacts[0].id : var.artifact_bucket_name
    type     = "S3"

    dynamic "encryption_key" {
      for_each = var.artifact_bucket_kms_key_arn != null ? [var.artifact_bucket_kms_key_arn] : []

      content {
        id   = encryption_key.value
        type = "KMS"
      }
    }
  }

  dynamic "stage" {
    for_each = var.stages

    content {
      name = stage.value.name

      dynamic "action" {
        for_each = stage.value.actions

        content {
          name             = action.value.name
          category         = action.value.category
          owner            = action.value.owner
          provider         = action.value.provider
          version          = action.value.version
          input_artifacts  = action.value.input_artifacts
          output_artifacts = action.value.output_artifacts
          run_order        = action.value.run_order
          region           = action.value.region
          namespace        = action.value.namespace
          configuration    = action.value.configuration
        }
      }
    }
  }

  tags = merge(local.common_tags, {
    Name = local.pipeline_name
  })
}
