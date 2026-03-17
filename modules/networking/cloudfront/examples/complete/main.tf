provider "aws" {
  region = var.aws_region
}

module "cloudfront" {
  source = "../../"

  project     = var.project
  environment = var.environment
  comment     = "Complete example CloudFront distribution"

  aliases             = var.aliases
  acm_certificate_arn = var.acm_certificate_arn

  s3_origin = {
    enabled                = true
    bucket_regional_domain = var.s3_bucket_regional_domain
    origin_id              = "s3-static"
  }

  custom_origins = [
    {
      domain_name     = var.api_origin_domain
      origin_id       = "api-origin"
      origin_protocol = "https-only"
    },
  ]

  default_cache_behavior = {
    target_origin_id       = "s3-static"
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }

  ordered_cache_behaviors = [
    {
      path_pattern           = "/api/*"
      target_origin_id       = "api-origin"
      viewer_protocol_policy = "https-only"
      allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
      cached_methods         = ["GET", "HEAD"]
      min_ttl                = 0
      default_ttl            = 0
      max_ttl                = 0
      forwarded_values = {
        query_string = true
        cookies      = "all"
        headers      = ["Authorization", "Origin"]
      }
    },
  ]

  custom_error_responses = [
    {
      error_code         = 404
      response_code      = 200
      response_page_path = "/index.html"
    },
  ]

  price_class = "PriceClass_100"
  web_acl_id  = var.web_acl_arn

  logging_config = {
    enabled = true
    bucket  = var.logging_bucket
    prefix  = "cloudfront/"
  }

  team        = var.team
  cost_center = var.cost_center
}
