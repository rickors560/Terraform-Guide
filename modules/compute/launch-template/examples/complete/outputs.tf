output "launch_template_id" {
  description = "Launch template ID"
  value       = module.launch_template.launch_template_id
}

output "launch_template_arn" {
  description = "Launch template ARN"
  value       = module.launch_template.launch_template_arn
}

output "latest_version" {
  description = "Latest version"
  value       = module.launch_template.latest_version
}
