################################################################################
# S3 Bucket for CUR Reports
################################################################################

resource "aws_s3_bucket" "cur" {
  count = var.create_s3_bucket ? 1 : 0

  bucket        = local.bucket_name
  force_destroy = var.s3_bucket_force_destroy

  tags = merge(local.common_tags, {
    Name = local.bucket_name
  })
}

resource "aws_s3_bucket_versioning" "cur" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.cur[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cur" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.cur[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cur" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.cur[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cur" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.cur[0].id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 365
      storage_class = "GLACIER"
    }

    expiration {
      days = 2557
    }
  }
}

resource "aws_s3_bucket_policy" "cur" {
  count = var.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.cur[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCURBucketAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "billingreports.amazonaws.com"
        }
        Action   = ["s3:GetBucketAcl", "s3:GetBucketPolicy"]
        Resource = aws_s3_bucket.cur[0].arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            "aws:SourceArn"     = "arn:aws:cur:us-east-1:${data.aws_caller_identity.current.account_id}:definition/*"
          }
        }
      },
      {
        Sid    = "AllowCURBucketWrite"
        Effect = "Allow"
        Principal = {
          Service = "billingreports.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cur[0].arn}/*"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
            "aws:SourceArn"     = "arn:aws:cur:us-east-1:${data.aws_caller_identity.current.account_id}:definition/*"
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
          aws_s3_bucket.cur[0].arn,
          "${aws_s3_bucket.cur[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.cur]
}

################################################################################
# Cost and Usage Report
################################################################################

resource "aws_cur_report_definition" "this" {
  report_name                = local.report_name
  time_unit                  = var.time_unit
  format                     = var.format
  compression                = var.compression
  additional_schema_elements = var.additional_schema_elements
  additional_artifacts       = var.additional_artifacts
  report_versioning          = var.report_versioning
  refresh_closed_reports     = var.refresh_closed_reports

  s3_bucket = var.create_s3_bucket ? aws_s3_bucket.cur[0].id : var.s3_bucket_name
  s3_region = var.create_s3_bucket ? data.aws_region.current.name : data.aws_region.current.name
  s3_prefix = var.s3_prefix

  depends_on = [aws_s3_bucket_policy.cur]
}
