output "metric_alarm_arns" {
  description = "Map of metric alarm names to their ARNs."
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.arn }
}

output "metric_alarm_ids" {
  description = "Map of metric alarm names to their IDs."
  value       = { for k, v in aws_cloudwatch_metric_alarm.this : k => v.id }
}

output "composite_alarm_arns" {
  description = "Map of composite alarm names to their ARNs."
  value       = { for k, v in aws_cloudwatch_composite_alarm.this : k => v.arn }
}

output "composite_alarm_ids" {
  description = "Map of composite alarm names to their IDs."
  value       = { for k, v in aws_cloudwatch_composite_alarm.this : k => v.id }
}
