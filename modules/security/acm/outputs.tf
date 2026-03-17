output "certificate_arn" {
  description = "The ARN of the ACM certificate."
  value       = aws_acm_certificate.this.arn
}

output "certificate_domain_name" {
  description = "The domain name of the certificate."
  value       = aws_acm_certificate.this.domain_name
}

output "certificate_status" {
  description = "The status of the certificate."
  value       = aws_acm_certificate.this.status
}

output "validation_record_fqdns" {
  description = "List of FQDNs for the DNS validation records."
  value       = [for record in aws_route53_record.validation : record.fqdn]
}

output "validated_certificate_arn" {
  description = "The ARN of the validated certificate (available after validation completes)."
  value       = try(aws_acm_certificate_validation.this[0].certificate_arn, aws_acm_certificate.this.arn)
}

output "domain_validation_options" {
  description = "Domain validation options for the certificate."
  value       = aws_acm_certificate.this.domain_validation_options
}
