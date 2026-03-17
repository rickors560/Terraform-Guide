output "policy_arn" {
  description = "The ARN of the IAM policy."
  value       = aws_iam_policy.this.arn
}

output "policy_id" {
  description = "The ID of the IAM policy."
  value       = aws_iam_policy.this.id
}

output "policy_name" {
  description = "The name of the IAM policy."
  value       = aws_iam_policy.this.name
}

output "policy_json" {
  description = "The generated policy document JSON."
  value       = data.aws_iam_policy_document.this.json
}
