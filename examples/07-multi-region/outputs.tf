###############################################################################
# Outputs — 07-multi-region
###############################################################################

# Application
output "app_url" {
  description = "Application URL (Route53 failover)"
  value       = "http://${var.site_domain}"
}

# Primary
output "primary_alb_dns" {
  description = "Primary ALB DNS name"
  value       = aws_lb.primary.dns_name
}

output "primary_vpc_id" {
  description = "Primary VPC ID"
  value       = aws_vpc.primary.id
}

output "primary_rds_endpoint" {
  description = "Primary RDS endpoint"
  value       = aws_db_instance.primary.endpoint
}

output "primary_s3_bucket" {
  description = "Primary S3 bucket name"
  value       = aws_s3_bucket.primary.id
}

# Secondary
output "secondary_alb_dns" {
  description = "Secondary ALB DNS name"
  value       = aws_lb.secondary.dns_name
}

output "secondary_vpc_id" {
  description = "Secondary VPC ID"
  value       = aws_vpc.secondary.id
}

output "secondary_rds_endpoint" {
  description = "Secondary RDS endpoint (read replica)"
  value       = aws_db_instance.secondary.endpoint
}

output "secondary_s3_bucket" {
  description = "Secondary S3 bucket name"
  value       = aws_s3_bucket.secondary.id
}

# Health checks
output "primary_health_check_id" {
  description = "Primary Route53 health check ID"
  value       = aws_route53_health_check.primary.id
}

output "secondary_health_check_id" {
  description = "Secondary Route53 health check ID"
  value       = aws_route53_health_check.secondary.id
}

# ACM
output "primary_certificate_arn" {
  description = "Primary ACM certificate ARN"
  value       = aws_acm_certificate.primary.arn
}

output "secondary_certificate_arn" {
  description = "Secondary ACM certificate ARN"
  value       = aws_acm_certificate.secondary.arn
}
