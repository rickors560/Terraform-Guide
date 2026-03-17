output "certificate_arn" {
  description = "ACM certificate ARN."
  value       = module.acm.certificate_arn
}

output "validated_certificate_arn" {
  description = "Validated ACM certificate ARN."
  value       = module.acm.validated_certificate_arn
}
