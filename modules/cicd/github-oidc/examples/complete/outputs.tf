output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider."
  value       = module.github_oidc.oidc_provider_arn
}

output "role_arn" {
  description = "ARN of the IAM role for GitHub Actions."
  value       = module.github_oidc.role_arn
}

output "role_name" {
  description = "Name of the IAM role."
  value       = module.github_oidc.role_name
}

output "allowed_subjects" {
  description = "Allowed OIDC subject claims."
  value       = module.github_oidc.allowed_subjects
}
