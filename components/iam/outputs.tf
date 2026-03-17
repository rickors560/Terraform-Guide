# -----------------------------------------------------------------------------
# IAM Component - Outputs
# -----------------------------------------------------------------------------

output "admin_group_arn" {
  description = "ARN of the admin IAM group"
  value       = aws_iam_group.admin.arn
}

output "admin_group_name" {
  description = "Name of the admin IAM group"
  value       = aws_iam_group.admin.name
}

output "developers_group_arn" {
  description = "ARN of the developers IAM group"
  value       = aws_iam_group.developers.arn
}

output "developers_group_name" {
  description = "Name of the developers IAM group"
  value       = aws_iam_group.developers.name
}

output "readonly_group_arn" {
  description = "ARN of the readonly IAM group"
  value       = aws_iam_group.readonly.arn
}

output "readonly_group_name" {
  description = "Name of the readonly IAM group"
  value       = aws_iam_group.readonly.name
}

output "enforce_mfa_policy_arn" {
  description = "ARN of the enforce MFA policy"
  value       = aws_iam_policy.enforce_mfa.arn
}

output "s3_read_only_policy_arn" {
  description = "ARN of the S3 read-only policy"
  value       = aws_iam_policy.s3_read_only.arn
}

output "user_arns" {
  description = "Map of IAM user names to their ARNs"
  value       = { for k, v in aws_iam_user.users : k => v.arn }
}

output "ec2_instance_role_arn" {
  description = "ARN of the EC2 instance role"
  value       = aws_iam_role.ec2_instance.arn
}

output "ec2_instance_role_name" {
  description = "Name of the EC2 instance role"
  value       = aws_iam_role.ec2_instance.name
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_instance.arn
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_instance.name
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.name
}

output "cross_account_role_arn" {
  description = "ARN of the cross-account assume role (empty if not created)"
  value       = length(aws_iam_role.cross_account) > 0 ? aws_iam_role.cross_account[0].arn : ""
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider (empty if not created)"
  value       = length(aws_iam_openid_connect_provider.github_actions) > 0 ? aws_iam_openid_connect_provider.github_actions[0].arn : ""
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions role (empty if not created)"
  value       = length(aws_iam_role.github_actions) > 0 ? aws_iam_role.github_actions[0].arn : ""
}
