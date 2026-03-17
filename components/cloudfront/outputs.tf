###############################################################################
# CloudFront Component — Outputs
###############################################################################

output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.main.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.main.arn
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name (*.cloudfront.net)"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "distribution_hosted_zone_id" {
  description = "CloudFront hosted zone ID (for Route53 alias records)"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "origin_bucket_id" {
  description = "S3 origin bucket name"
  value       = aws_s3_bucket.origin.id
}

output "origin_bucket_arn" {
  description = "S3 origin bucket ARN"
  value       = aws_s3_bucket.origin.arn
}

output "origin_bucket_regional_domain" {
  description = "S3 origin bucket regional domain name"
  value       = aws_s3_bucket.origin.bucket_regional_domain_name
}

output "logs_bucket_id" {
  description = "S3 logs bucket name"
  value       = aws_s3_bucket.logs.id
}

output "oac_id" {
  description = "Origin Access Control ID"
  value       = aws_cloudfront_origin_access_control.main.id
}
