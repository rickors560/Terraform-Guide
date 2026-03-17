output "db_credentials_arn" {
  description = "Database credentials secret ARN."
  value       = module.db_credentials.secret_arn
}

output "api_key_arn" {
  description = "API key secret ARN."
  value       = module.api_key.secret_arn
}
