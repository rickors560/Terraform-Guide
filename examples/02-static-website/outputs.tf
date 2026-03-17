###############################################################################
# Outputs — 02-static-website
###############################################################################

output "website_url" {
  description = "Website URL (HTTPS)"
  value       = "https://${var.site_domain}"
}

output "www_url" {
  description = "Website URL with www prefix"
  value       = "https://www.${var.site_domain}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (use for cache invalidation)"
  value       = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.website.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.website.arn
}

output "acm_certificate_arn" {
  description = "ACM certificate ARN"
  value       = aws_acm_certificate.main.arn
}

output "invalidation_command" {
  description = "Command to invalidate CloudFront cache after deploying new content"
  value       = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.website.id} --paths '/*'"
}

output "sync_command" {
  description = "Command to sync local build directory to S3"
  value       = "aws s3 sync ./dist s3://${aws_s3_bucket.website.id} --delete"
}
