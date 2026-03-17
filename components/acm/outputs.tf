###############################################################################
# ACM Component — Outputs
###############################################################################

output "certificate_arn" {
  description = "ARN of the regional ACM certificate"
  value       = aws_acm_certificate.main.arn
}

output "certificate_domain_name" {
  description = "Domain name of the certificate"
  value       = aws_acm_certificate.main.domain_name
}

output "certificate_status" {
  description = "Status of the regional certificate"
  value       = aws_acm_certificate.main.status
}

output "certificate_not_after" {
  description = "Expiration date of the certificate"
  value       = aws_acm_certificate.main.not_after
}

output "domain_validation_options" {
  description = "DNS validation records (for manual validation)"
  value = [for dvo in aws_acm_certificate.main.domain_validation_options : {
    domain_name = dvo.domain_name
    name        = dvo.resource_record_name
    type        = dvo.resource_record_type
    value       = dvo.resource_record_value
  }]
}

output "validated_certificate_arn" {
  description = "ARN of the validated regional certificate"
  value       = var.route53_zone_id != "" ? aws_acm_certificate_validation.main[0].certificate_arn : aws_acm_certificate.main.arn
}

output "cloudfront_certificate_arn" {
  description = "ARN of the CloudFront (us-east-1) certificate (if created)"
  value       = var.create_cloudfront_certificate ? aws_acm_certificate.cloudfront[0].arn : null
}

output "validated_cloudfront_certificate_arn" {
  description = "ARN of the validated CloudFront certificate (if created)"
  value       = var.create_cloudfront_certificate && var.route53_zone_id != "" ? aws_acm_certificate_validation.cloudfront[0].certificate_arn : null
}
