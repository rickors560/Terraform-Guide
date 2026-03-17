output "bus_name" {
  description = "Name of the EventBridge event bus."
  value       = var.create_bus ? aws_cloudwatch_event_bus.this[0].name : var.bus_name
}

output "bus_arn" {
  description = "ARN of the EventBridge event bus."
  value       = var.create_bus ? aws_cloudwatch_event_bus.this[0].arn : null
}

output "rule_arns" {
  description = "Map of rule names to their ARNs."
  value       = { for k, v in aws_cloudwatch_event_rule.this : k => v.arn }
}

output "rule_names" {
  description = "Map of rule keys to their full names."
  value       = { for k, v in aws_cloudwatch_event_rule.this : k => v.name }
}

output "archive_arns" {
  description = "Map of archive names to their ARNs."
  value       = { for k, v in aws_cloudwatch_event_archive.this : k => v.arn }
}
