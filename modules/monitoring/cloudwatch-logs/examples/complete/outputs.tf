output "log_group_name" {
  description = "Name of the CloudWatch Log Group."
  value       = module.cloudwatch_logs.log_group_name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch Log Group."
  value       = module.cloudwatch_logs.log_group_arn
}

output "metric_filter_ids" {
  description = "Metric filter IDs."
  value       = module.cloudwatch_logs.metric_filter_ids
}
