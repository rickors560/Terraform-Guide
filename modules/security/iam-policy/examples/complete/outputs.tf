output "policy_arn" {
  description = "S3 policy ARN."
  value       = module.s3_policy.policy_arn
}

output "policy_json" {
  description = "Generated policy JSON."
  value       = module.s3_policy.policy_json
}
