################################################################################
# S3 Bucket for CloudTrail Logs
################################################################################

resource "aws_s3_bucket" "cloudtrail" {
  count = var.create_s3_bucket ? 1 : 0

  bucket        = local.bucket_name
  force_destroy = var.s3_bucket_force_destroy

  tags = merge(local.common_tags, {
    Name = local.bucket_name
  })
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null ? true : false
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id

  rule {
    id     = "transition-to-glacier"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 2557
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${local.trail_name}"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail[0].arn}/${var.s3_key_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
            "aws:SourceArn" = "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/${local.trail_name}"
          }
        }
      },
      {
        Sid    = "DenyUnencryptedTransport"
        Effect = "Deny"
        Principal = {
          AWS = "*"
        }
        Action   = "s3:*"
        Resource = [
          aws_s3_bucket.cloudtrail[0].arn,
          "${aws_s3_bucket.cloudtrail[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.cloudtrail]
}

################################################################################
# CloudWatch Log Group for CloudTrail
################################################################################

resource "aws_cloudwatch_log_group" "cloudtrail" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/cloudtrail/${local.trail_name}"
  retention_in_days = var.cloudwatch_log_group_retention
  kms_key_id        = var.kms_key_arn

  tags = local.common_tags
}

################################################################################
# IAM Role for CloudWatch Logs
################################################################################

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name = "${local.name_prefix}-cloudtrail-cw-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudTrailAssume"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name = "${local.name_prefix}-cloudtrail-cw-policy"
  role = aws_iam_role.cloudtrail_cloudwatch[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*"
      }
    ]
  })
}

################################################################################
# CloudTrail
################################################################################

resource "aws_cloudtrail" "this" {
  name                          = local.trail_name
  s3_bucket_name                = var.create_s3_bucket ? aws_s3_bucket.cloudtrail[0].id : var.s3_bucket_name
  s3_key_prefix                 = var.s3_key_prefix
  is_multi_region_trail         = var.is_multi_region_trail
  is_organization_trail         = var.is_organization_trail
  enable_log_file_validation    = var.enable_log_file_validation
  include_global_service_events = var.include_global_service_events
  kms_key_id                    = var.kms_key_arn
  sns_topic_name                = var.sns_topic_name

  cloud_watch_logs_group_arn = var.enable_cloudwatch_logs ? "${aws_cloudwatch_log_group.cloudtrail[0].arn}:*" : null
  cloud_watch_logs_role_arn  = var.enable_cloudwatch_logs ? aws_iam_role.cloudtrail_cloudwatch[0].arn : null

  dynamic "event_selector" {
    for_each = var.enable_management_events ? [1] : []

    content {
      read_write_type           = var.management_read_write_type
      include_management_events = true
      exclude_management_event_sources = var.management_exclude_sources
    }
  }

  dynamic "event_selector" {
    for_each = var.data_events

    content {
      read_write_type           = event_selector.value.read_write_type
      include_management_events = event_selector.value.include_management_events

      dynamic "data_resource" {
        for_each = event_selector.value.data_resources

        content {
          type   = data_resource.value.type
          values = data_resource.value.values
        }
      }
    }
  }

  dynamic "insight_selector" {
    for_each = var.insight_selectors

    content {
      insight_type = insight_selector.value.insight_type
    }
  }

  tags = merge(local.common_tags, {
    Name = local.trail_name
  })

  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_iam_role_policy.cloudtrail_cloudwatch,
  ]
}
