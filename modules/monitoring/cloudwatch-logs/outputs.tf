output "log_group_name" {
  description = "Name of the CloudWatch Log Group."
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch Log Group."
  value       = aws_cloudwatch_log_group.this.arn
}

output "metric_filter_ids" {
  description = "Map of metric filter names to their IDs."
  value       = { for k, v in aws_cloudwatch_log_metric_filter.this : k => v.id }
}

output "subscription_filter_ids" {
  description = "Map of subscription filter names to their IDs."
  value       = { for k, v in aws_cloudwatch_log_subscription_filter.this : k => v.id }
}
