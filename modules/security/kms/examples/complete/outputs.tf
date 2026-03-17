output "key_arn" {
  description = "KMS key ARN."
  value       = module.kms.key_arn
}

output "alias_name" {
  description = "KMS alias name."
  value       = module.kms.alias_name
}
