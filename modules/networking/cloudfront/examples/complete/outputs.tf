output "distribution_id" {
  description = "CloudFront distribution ID."
  value       = module.cloudfront.distribution_id
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name."
  value       = module.cloudfront.distribution_domain_name
}
