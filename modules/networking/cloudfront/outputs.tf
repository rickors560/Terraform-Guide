output "distribution_id" {
  description = "The ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "The ARN of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "The domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_hosted_zone_id" {
  description = "The hosted zone ID of the CloudFront distribution (for Route53 alias records)."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "distribution_status" {
  description = "The status of the CloudFront distribution."
  value       = aws_cloudfront_distribution.this.status
}

output "oac_id" {
  description = "The ID of the Origin Access Control."
  value       = try(aws_cloudfront_origin_access_control.this[0].id, null)
}
