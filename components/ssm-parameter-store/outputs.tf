# -----------------------------------------------------------------------------
# SSM Parameter Store Component - Outputs
# -----------------------------------------------------------------------------

output "parameter_prefix" {
  description = "Hierarchical prefix for all parameters"
  value       = local.param_prefix
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for SecureString parameters"
  value       = aws_kms_key.ssm.arn
}

output "kms_key_alias" {
  description = "Alias of the KMS key"
  value       = aws_kms_alias.ssm.name
}

output "app_config_parameter_arns" {
  description = "ARNs of application configuration parameters"
  value = {
    name            = aws_ssm_parameter.app_name.arn
    environment     = aws_ssm_parameter.app_environment.arn
    log_level       = aws_ssm_parameter.app_log_level.arn
    port            = aws_ssm_parameter.app_port.arn
    max_connections = aws_ssm_parameter.app_max_connections.arn
    feature_flags   = aws_ssm_parameter.feature_flags.arn
    allowed_origins = aws_ssm_parameter.allowed_origins.arn
  }
}

output "database_parameter_arns" {
  description = "ARNs of database configuration parameters"
  value = {
    host              = aws_ssm_parameter.db_host.arn
    port              = aws_ssm_parameter.db_port.arn
    name              = aws_ssm_parameter.db_name.arn
    username          = aws_ssm_parameter.db_username.arn
    password          = aws_ssm_parameter.db_password.arn
    connection_string = aws_ssm_parameter.db_connection_string.arn
  }
}

output "cache_parameter_arns" {
  description = "ARNs of cache configuration parameters"
  value = {
    host       = aws_ssm_parameter.cache_host.arn
    port       = aws_ssm_parameter.cache_port.arn
    auth_token = aws_ssm_parameter.cache_auth_token.arn
  }
}

output "ssm_read_all_policy_arn" {
  description = "ARN of the IAM policy for full SSM parameter read access"
  value       = aws_iam_policy.ssm_read_all.arn
}

output "ssm_read_config_policy_arn" {
  description = "ARN of the IAM policy for config-only (non-sensitive) parameter read access"
  value       = aws_iam_policy.ssm_read_config_only.arn
}
