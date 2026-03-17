# -----------------------------------------------------------------------------
# Secrets Manager Component - Outputs
# -----------------------------------------------------------------------------

output "kms_key_arn" {
  description = "ARN of the KMS key used for secrets encryption"
  value       = aws_kms_key.secrets.arn
}

output "kms_key_alias" {
  description = "Alias of the KMS key"
  value       = aws_kms_alias.secrets.name
}

output "database_secret_arn" {
  description = "ARN of the database credentials secret"
  value       = aws_secretsmanager_secret.database.arn
}

output "database_secret_name" {
  description = "Name of the database credentials secret"
  value       = aws_secretsmanager_secret.database.name
}

output "api_key_secret_arn" {
  description = "ARN of the API key secret"
  value       = aws_secretsmanager_secret.api_key.arn
}

output "api_key_secret_name" {
  description = "Name of the API key secret"
  value       = aws_secretsmanager_secret.api_key.name
}

output "app_config_secret_arn" {
  description = "ARN of the application configuration secret"
  value       = aws_secretsmanager_secret.app_config.arn
}

output "app_config_secret_name" {
  description = "Name of the application configuration secret"
  value       = aws_secretsmanager_secret.app_config.name
}

output "rotation_role_arn" {
  description = "ARN of the rotation Lambda IAM role (empty if rotation disabled)"
  value       = length(aws_iam_role.rotation_lambda) > 0 ? aws_iam_role.rotation_lambda[0].arn : ""
}
