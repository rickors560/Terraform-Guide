output "web_security_group_id" {
  description = "Web tier security group ID."
  value       = module.web_sg.security_group_id
}

output "app_security_group_id" {
  description = "App tier security group ID."
  value       = module.app_sg.security_group_id
}
