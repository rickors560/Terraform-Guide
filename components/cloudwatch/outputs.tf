# -----------------------------------------------------------------------------
# CloudWatch Component - Outputs
# -----------------------------------------------------------------------------

output "application_log_group_name" {
  description = "Name of the application log group"
  value       = aws_cloudwatch_log_group.application.name
}

output "application_log_group_arn" {
  description = "ARN of the application log group"
  value       = aws_cloudwatch_log_group.application.arn
}

output "access_log_group_name" {
  description = "Name of the access log group"
  value       = aws_cloudwatch_log_group.access.name
}

output "error_log_group_name" {
  description = "Name of the error log group"
  value       = aws_cloudwatch_log_group.error.name
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

output "cpu_high_alarm_arn" {
  description = "ARN of the CPU high alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_high.arn
}

output "cpu_critical_alarm_arn" {
  description = "ARN of the CPU critical alarm"
  value       = aws_cloudwatch_metric_alarm.cpu_critical.arn
}

output "memory_high_alarm_arn" {
  description = "ARN of the memory high alarm"
  value       = aws_cloudwatch_metric_alarm.memory_high.arn
}

output "disk_high_alarm_arn" {
  description = "ARN of the disk high alarm"
  value       = aws_cloudwatch_metric_alarm.disk_high.arn
}

output "composite_alarm_arn" {
  description = "ARN of the system health composite alarm"
  value       = aws_cloudwatch_composite_alarm.system_health.arn
}

output "error_metric_filter_name" {
  description = "Name of the error count metric filter"
  value       = aws_cloudwatch_log_metric_filter.error_count.name
}

output "custom_namespace" {
  description = "Custom CloudWatch namespace for application metrics"
  value       = "${var.project_name}/${var.environment}"
}
