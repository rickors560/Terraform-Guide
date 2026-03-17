output "bus_name" {
  description = "Name of the EventBridge event bus."
  value       = module.eventbridge.bus_name
}

output "bus_arn" {
  description = "ARN of the EventBridge event bus."
  value       = module.eventbridge.bus_arn
}

output "rule_arns" {
  description = "Map of rule ARNs."
  value       = module.eventbridge.rule_arns
}

output "archive_arns" {
  description = "Map of archive ARNs."
  value       = module.eventbridge.archive_arns
}
