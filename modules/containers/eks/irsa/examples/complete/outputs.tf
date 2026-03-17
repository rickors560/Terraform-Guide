output "role_arn" {
  description = "IAM role ARN"
  value       = module.irsa.role_arn
}

output "role_name" {
  description = "IAM role name"
  value       = module.irsa.role_name
}
