output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC identity provider."
  value       = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn
}

output "oidc_provider_url" {
  description = "URL of the GitHub OIDC identity provider."
  value       = local.github_oidc_url
}

output "role_arn" {
  description = "ARN of the IAM role for GitHub Actions."
  value       = aws_iam_role.github_actions.arn
}

output "role_name" {
  description = "Name of the IAM role for GitHub Actions."
  value       = aws_iam_role.github_actions.name
}

output "allowed_subjects" {
  description = "List of allowed OIDC subject claims."
  value       = local.all_allowed_subjects
}
