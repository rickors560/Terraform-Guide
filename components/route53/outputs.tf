###############################################################################
# Route53 Component — Outputs
###############################################################################

output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "zone_arn" {
  description = "Route53 hosted zone ARN"
  value       = aws_route53_zone.main.arn
}

output "name_servers" {
  description = "Name servers for the hosted zone (delegate from registrar)"
  value       = aws_route53_zone.main.name_servers
}

output "domain_name" {
  description = "Domain name of the hosted zone"
  value       = aws_route53_zone.main.name
}

output "health_check_id" {
  description = "Health check ID (if created)"
  value       = var.health_check_fqdn != "" ? aws_route53_health_check.main[0].id : null
}

output "a_record_fqdns" {
  description = "FQDNs of A records"
  value       = { for k, v in aws_route53_record.a_records : k => v.fqdn }
}

output "alias_record_fqdns" {
  description = "FQDNs of alias A records"
  value       = { for k, v in aws_route53_record.alias_records : k => v.fqdn }
}

output "cname_record_fqdns" {
  description = "FQDNs of CNAME records"
  value       = { for k, v in aws_route53_record.cname_records : k => v.fqdn }
}
