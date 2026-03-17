output "dashboard_name" {
  description = "Name of the CloudWatch Dashboard."
  value       = module.dashboard.dashboard_name
}

output "dashboard_arn" {
  description = "ARN of the CloudWatch Dashboard."
  value       = module.dashboard.dashboard_arn
}
