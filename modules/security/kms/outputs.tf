output "key_id" {
  description = "The globally unique identifier for the KMS key."
  value       = aws_kms_key.this.key_id
}

output "key_arn" {
  description = "The ARN of the KMS key."
  value       = aws_kms_key.this.arn
}

output "alias_arn" {
  description = "The ARN of the primary KMS alias."
  value       = aws_kms_alias.this.arn
}

output "alias_name" {
  description = "The name of the primary KMS alias."
  value       = aws_kms_alias.this.name
}

output "grant_ids" {
  description = "Map of grant names to grant IDs."
  value       = { for k, v in aws_kms_grant.this : k => v.grant_id }
}

output "grant_tokens" {
  description = "Map of grant names to grant tokens."
  value       = { for k, v in aws_kms_grant.this : k => v.grant_token }
}
