output "zone_id" {
  description = "The hosted zone ID."
  value       = local.zone_id
}

output "zone_name" {
  description = "The hosted zone name."
  value       = var.zone_name
}

output "zone_arn" {
  description = "The ARN of the hosted zone."
  value       = try(aws_route53_zone.this[0].arn, null)
}

output "name_servers" {
  description = "List of name servers for the hosted zone."
  value       = try(aws_route53_zone.this[0].name_servers, [])
}

output "record_fqdns" {
  description = "Map of record names to their FQDNs."
  value       = { for k, v in aws_route53_record.this : k => v.fqdn }
}

output "health_check_ids" {
  description = "Map of health check names to their IDs."
  value       = { for k, v in aws_route53_health_check.this : k => v.id }
}
