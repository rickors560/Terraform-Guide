output "zone_id" {
  description = "Hosted zone ID."
  value       = module.route53.zone_id
}

output "name_servers" {
  description = "Name servers."
  value       = module.route53.name_servers
}

output "record_fqdns" {
  description = "Record FQDNs."
  value       = module.route53.record_fqdns
}
