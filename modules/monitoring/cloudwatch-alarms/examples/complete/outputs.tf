output "metric_alarm_arns" {
  description = "Map of metric alarm names to their ARNs."
  value       = module.cloudwatch_alarms.metric_alarm_arns
}

output "composite_alarm_arns" {
  description = "Map of composite alarm names to their ARNs."
  value       = module.cloudwatch_alarms.composite_alarm_arns
}

output "sns_topic_arn" {
  description = "SNS topic ARN used for notifications."
  value       = module.sns_topic.topic_arn
}
