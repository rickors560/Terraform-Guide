###############################################################################
# Origin Access Control (for S3)
###############################################################################

resource "aws_cloudfront_origin_access_control" "this" {
  count = var.s3_origin.enabled ? 1 : 0

  name                              = "${local.name_prefix}-oac"
  description                       = "OAC for ${local.name_prefix} CloudFront distribution"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

###############################################################################
# CloudFront Distribution
###############################################################################

resource "aws_cloudfront_distribution" "this" {
  comment             = var.comment != "" ? var.comment : "${local.name_prefix} distribution"
  enabled             = var.enabled
  is_ipv6_enabled     = var.is_ipv6_enabled
  price_class         = var.price_class
  default_root_object = var.default_root_object
  aliases             = var.aliases
  web_acl_id          = var.web_acl_id

  # S3 Origin
  dynamic "origin" {
    for_each = var.s3_origin.enabled ? [var.s3_origin] : []
    content {
      domain_name              = origin.value.bucket_regional_domain
      origin_id                = origin.value.origin_id
      origin_path              = origin.value.origin_path
      origin_access_control_id = aws_cloudfront_origin_access_control.this[0].id
    }
  }

  # Custom Origins
  dynamic "origin" {
    for_each = var.custom_origins
    content {
      domain_name = origin.value.domain_name
      origin_id   = origin.value.origin_id
      origin_path = origin.value.origin_path

      custom_origin_config {
        http_port                = origin.value.http_port
        https_port               = origin.value.https_port
        origin_protocol_policy   = origin.value.origin_protocol
        origin_ssl_protocols     = origin.value.origin_ssl_protocols
        origin_keepalive_timeout = origin.value.origin_keepalive_timeout
        origin_read_timeout      = origin.value.origin_read_timeout
      }

      dynamic "custom_header" {
        for_each = origin.value.custom_headers
        content {
          name  = custom_header.value.name
          value = custom_header.value.value
        }
      }
    }
  }

  # Default Cache Behavior
  default_cache_behavior {
    target_origin_id       = var.default_cache_behavior.target_origin_id
    viewer_protocol_policy = var.default_cache_behavior.viewer_protocol_policy
    allowed_methods        = var.default_cache_behavior.allowed_methods
    cached_methods         = var.default_cache_behavior.cached_methods
    compress               = var.default_cache_behavior.compress

    cache_policy_id            = var.default_cache_behavior.cache_policy_id
    origin_request_policy_id   = var.default_cache_behavior.origin_request_policy_id
    response_headers_policy_id = var.default_cache_behavior.response_headers_policy_id

    min_ttl     = var.default_cache_behavior.cache_policy_id == null ? var.default_cache_behavior.min_ttl : null
    default_ttl = var.default_cache_behavior.cache_policy_id == null ? var.default_cache_behavior.default_ttl : null
    max_ttl     = var.default_cache_behavior.cache_policy_id == null ? var.default_cache_behavior.max_ttl : null

    dynamic "forwarded_values" {
      for_each = var.default_cache_behavior.cache_policy_id == null && var.default_cache_behavior.forwarded_values != null ? [var.default_cache_behavior.forwarded_values] : (var.default_cache_behavior.cache_policy_id == null ? [{ query_string = false, cookies = "none", headers = [] }] : [])
      content {
        query_string = forwarded_values.value.query_string
        headers      = forwarded_values.value.headers

        cookies {
          forward = forwarded_values.value.cookies
        }
      }
    }
  }

  # Ordered Cache Behaviors
  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behaviors
    content {
      path_pattern           = ordered_cache_behavior.value.path_pattern
      target_origin_id       = ordered_cache_behavior.value.target_origin_id
      viewer_protocol_policy = ordered_cache_behavior.value.viewer_protocol_policy
      allowed_methods        = ordered_cache_behavior.value.allowed_methods
      cached_methods         = ordered_cache_behavior.value.cached_methods
      compress               = ordered_cache_behavior.value.compress

      cache_policy_id            = ordered_cache_behavior.value.cache_policy_id
      origin_request_policy_id   = ordered_cache_behavior.value.origin_request_policy_id
      response_headers_policy_id = ordered_cache_behavior.value.response_headers_policy_id

      min_ttl     = ordered_cache_behavior.value.cache_policy_id == null ? ordered_cache_behavior.value.min_ttl : null
      default_ttl = ordered_cache_behavior.value.cache_policy_id == null ? ordered_cache_behavior.value.default_ttl : null
      max_ttl     = ordered_cache_behavior.value.cache_policy_id == null ? ordered_cache_behavior.value.max_ttl : null

      dynamic "forwarded_values" {
        for_each = ordered_cache_behavior.value.cache_policy_id == null && ordered_cache_behavior.value.forwarded_values != null ? [ordered_cache_behavior.value.forwarded_values] : (ordered_cache_behavior.value.cache_policy_id == null ? [{ query_string = false, cookies = "none", headers = [] }] : [])
        content {
          query_string = forwarded_values.value.query_string
          headers      = forwarded_values.value.headers

          cookies {
            forward = forwarded_values.value.cookies
          }
        }
      }
    }
  }

  # Custom Error Responses
  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  # Viewer Certificate
  viewer_certificate {
    acm_certificate_arn            = var.acm_certificate_arn
    cloudfront_default_certificate = var.acm_certificate_arn == null
    minimum_protocol_version       = var.acm_certificate_arn != null ? var.minimum_protocol_version : "TLSv1"
    ssl_support_method             = var.acm_certificate_arn != null ? var.ssl_support_method : null
  }

  # Geo Restriction
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  # Logging
  dynamic "logging_config" {
    for_each = var.logging_config.enabled ? [var.logging_config] : []
    content {
      bucket          = logging_config.value.bucket
      prefix          = logging_config.value.prefix
      include_cookies = logging_config.value.include_cookies
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cloudfront"
  })
}
