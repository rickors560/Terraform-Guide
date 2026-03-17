###############################################################################
# CloudFront Component — Distribution with S3 Origin (OAC), Cache Policy
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
  #   key            = "components/cloudfront/terraform.tfstate"
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
      Component   = "cloudfront"
    }
  }
}

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "cors_s3" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_response_headers_policy" "security" {
  name = "Managed-SecurityHeadersPolicy"
}

# -----------------------------------------------------------------------------
# S3 Origin Bucket
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "origin" {
  bucket        = "${var.project_name}-${var.environment}-cdn-origin-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.environment != "prod"

  tags = {
    Name = "${var.project_name}-${var.environment}-cdn-origin"
  }
}

resource "aws_s3_bucket_versioning" "origin" {
  bucket = aws_s3_bucket.origin.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "origin" {
  bucket = aws_s3_bucket.origin.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "origin" {
  bucket                  = aws_s3_bucket.origin.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "origin" {
  bucket = aws_s3_bucket.origin.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# S3 bucket policy allowing CloudFront OAC access
resource "aws_s3_bucket_policy" "origin" {
  bucket = aws_s3_bucket.origin.id

  depends_on = [aws_s3_bucket_public_access_block.origin]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOAC"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.origin.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.main.arn
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# Origin Access Control
# -----------------------------------------------------------------------------

resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for ${var.project_name}-${var.environment} S3 origin"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -----------------------------------------------------------------------------
# Custom Cache Policy (optional, in addition to managed policies)
# -----------------------------------------------------------------------------

resource "aws_cloudfront_cache_policy" "custom" {
  count = var.custom_cache_policy ? 1 : 0

  name        = "${var.project_name}-${var.environment}-cache-policy"
  comment     = "Custom cache policy for ${var.project_name}-${var.environment}"
  default_ttl = var.default_ttl
  max_ttl     = var.max_ttl
  min_ttl     = var.min_ttl

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }

    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

# -----------------------------------------------------------------------------
# CloudFront Distribution
# -----------------------------------------------------------------------------

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.project_name}-${var.environment} CDN distribution"
  default_root_object = var.default_root_object
  price_class         = var.price_class
  http_version        = "http2and3"
  aliases             = length(var.domain_aliases) > 0 ? var.domain_aliases : null
  web_acl_id          = var.web_acl_arn != "" ? var.web_acl_arn : null

  origin {
    domain_name              = aws_s3_bucket.origin.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id
    origin_id                = "s3-origin"
    origin_path              = var.origin_path

    origin_shield {
      enabled              = var.origin_shield_enabled
      origin_shield_region = var.origin_shield_enabled ? var.aws_region : null
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"

    cache_policy_id            = var.custom_cache_policy ? aws_cloudfront_cache_policy.custom[0].id : data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.cors_s3.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.security.id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  # Custom error responses
  custom_error_response {
    error_code            = 403
    error_caching_min_ttl = 10
    response_code         = 404
    response_page_path    = var.custom_error_page_404
  }

  custom_error_response {
    error_code            = 404
    error_caching_min_ttl = 10
    response_code         = 404
    response_page_path    = var.custom_error_page_404
  }

  custom_error_response {
    error_code            = 500
    error_caching_min_ttl = 5
    response_code         = 500
    response_page_path    = var.custom_error_page_500
  }

  restrictions {
    geo_restriction {
      restriction_type = length(var.geo_restriction_locations) > 0 ? var.geo_restriction_type : "none"
      locations        = length(var.geo_restriction_locations) > 0 ? var.geo_restriction_locations : []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = length(var.domain_aliases) == 0
    acm_certificate_arn            = length(var.domain_aliases) > 0 ? var.acm_certificate_arn : null
    ssl_support_method             = length(var.domain_aliases) > 0 ? "sni-only" : null
    minimum_protocol_version       = length(var.domain_aliases) > 0 ? "TLSv1.2_2021" : null
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs.bucket_domain_name
    prefix          = "cloudfront-logs/"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-distribution"
  }
}

# -----------------------------------------------------------------------------
# CloudFront Logs Bucket
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "logs" {
  bucket        = "${var.project_name}-${var.environment}-cdn-logs-${data.aws_caller_identity.current.account_id}"
  force_destroy = var.environment != "prod"

  tags = {
    Name = "${var.project_name}-${var.environment}-cdn-logs"
  }
}

resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "logs" {
  depends_on = [aws_s3_bucket_ownership_controls.logs]
  bucket     = aws_s3_bucket.logs.id
  acl        = "log-delivery-write"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"
    filter { prefix = "" }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
