################################################################################
# IAM Role for CodeBuild
################################################################################

resource "aws_iam_role" "codebuild" {
  count = var.create_iam_role ? 1 : 0

  name = "${local.name_prefix}-codebuild-${var.build_project_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCodeBuildAssume"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "codebuild" {
  count = var.create_iam_role ? 1 : 0

  name = "${local.name_prefix}-codebuild-${var.build_project_name}-policy"
  role = aws_iam_role.codebuild[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "CloudWatchLogsAccess"
          Effect = "Allow"
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.project_name}",
            "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/${local.project_name}:*"
          ]
        },
        {
          Sid    = "S3ArtifactAccess"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:GetObjectVersion",
            "s3:GetBucketVersioning",
            "s3:PutObject"
          ]
          Resource = ["arn:${data.aws_partition.current.partition}:s3:::*"]
        },
        {
          Sid    = "ECRAccess"
          Effect = "Allow"
          Action = [
            "ecr:BatchCheckLayerAvailability",
            "ecr:CompleteLayerUpload",
            "ecr:GetAuthorizationToken",
            "ecr:InitiateLayerUpload",
            "ecr:PutImage",
            "ecr:UploadLayerPart",
            "ecr:BatchGetImage",
            "ecr:GetDownloadUrlForLayer"
          ]
          Resource = ["*"]
        },
        {
          Sid    = "CodeBuildReportAccess"
          Effect = "Allow"
          Action = [
            "codebuild:CreateReportGroup",
            "codebuild:CreateReport",
            "codebuild:UpdateReport",
            "codebuild:BatchPutTestCases",
            "codebuild:BatchPutCodeCoverages"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:report-group/${local.project_name}-*"
          ]
        },
      ],
      length(var.environment_variables_ssm) > 0 ? [
        {
          Sid    = "SSMParameterAccess"
          Effect = "Allow"
          Action = [
            "ssm:GetParameters",
            "ssm:GetParameter"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/*"
          ]
        }
      ] : [],
      length(var.environment_variables_secrets_manager) > 0 ? [
        {
          Sid    = "SecretsManagerAccess"
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue"
          ]
          Resource = [
            "arn:${data.aws_partition.current.partition}:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:*"
          ]
        }
      ] : [],
      var.vpc_config != null ? [
        {
          Sid    = "VPCAccess"
          Effect = "Allow"
          Action = [
            "ec2:CreateNetworkInterface",
            "ec2:DescribeDhcpOptions",
            "ec2:DescribeNetworkInterfaces",
            "ec2:DeleteNetworkInterface",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:DescribeVpcs",
            "ec2:CreateNetworkInterfacePermission"
          ]
          Resource = ["*"]
        }
      ] : [],
      [for stmt in var.additional_iam_statements : {
        Sid       = stmt.sid
        Effect    = stmt.effect
        Action    = stmt.actions
        Resource  = stmt.resources
      }],
    )
  })
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = var.create_iam_role ? toset(var.additional_iam_policy_arns) : toset([])

  role       = aws_iam_role.codebuild[0].name
  policy_arn = each.value
}

################################################################################
# CloudWatch Log Group
################################################################################

resource "aws_cloudwatch_log_group" "codebuild" {
  count = var.cloudwatch_logs_enabled ? 1 : 0

  name              = coalesce(var.cloudwatch_log_group_name, "/aws/codebuild/${local.project_name}")
  retention_in_days = 30

  tags = local.common_tags
}

################################################################################
# CodeBuild Project
################################################################################

resource "aws_codebuild_project" "this" {
  name                   = local.project_name
  description            = var.description
  build_timeout          = var.build_timeout
  queued_timeout         = var.queued_timeout
  service_role           = var.create_iam_role ? aws_iam_role.codebuild[0].arn : var.existing_role_arn
  concurrent_build_limit = var.concurrent_build_limit

  environment {
    compute_type                = var.compute_type
    image                       = var.image
    type                        = var.environment_type
    privileged_mode             = var.privileged_mode
    image_pull_credentials_type = var.image_pull_credentials_type
    certificate                 = var.certificate

    dynamic "environment_variable" {
      for_each = local.environment_variables

      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
        type  = environment_variable.value.type
      }
    }
  }

  source {
    type            = var.source_type
    location        = var.source_location
    git_clone_depth = var.source_type != "CODEPIPELINE" && var.source_type != "NO_SOURCE" && var.source_type != "S3" ? var.git_clone_depth : null
    buildspec       = var.buildspec
    report_build_status = var.source_type == "GITHUB" || var.source_type == "GITHUB_ENTERPRISE" || var.source_type == "BITBUCKET" ? var.report_build_status : null
  }

  dynamic "source_version" {
    for_each = var.source_version != null ? [var.source_version] : []

    content {}
  }

  artifacts {
    type                   = var.artifacts_type
    location               = var.artifacts_location
    name                   = var.artifacts_name
    packaging              = var.artifacts_packaging
    encryption_disabled    = var.artifacts_encryption_disabled
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []

    content {
      vpc_id             = vpc_config.value.vpc_id
      subnets            = vpc_config.value.subnets
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  cache {
    type     = var.cache_type
    location = var.cache_type == "S3" ? var.cache_location : null
    modes    = var.cache_type == "LOCAL" ? var.cache_modes : null
  }

  logs_config {
    cloudwatch_logs {
      status      = var.cloudwatch_logs_enabled ? "ENABLED" : "DISABLED"
      group_name  = var.cloudwatch_logs_enabled ? coalesce(var.cloudwatch_log_group_name, "/aws/codebuild/${local.project_name}") : null
      stream_name = var.cloudwatch_log_stream_name
    }

    s3_logs {
      status              = var.s3_logs_enabled ? "ENABLED" : "DISABLED"
      location            = var.s3_logs_location
      encryption_disabled = var.s3_logs_encryption_disabled
    }
  }

  tags = merge(local.common_tags, {
    Name = local.project_name
  })
}
