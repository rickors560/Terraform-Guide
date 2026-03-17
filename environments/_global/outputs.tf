################################################################################
# IAM Role Outputs
################################################################################

output "admin_role_arn" {
  description = "ARN of the admin IAM role."
  value       = aws_iam_role.admin.arn
}

output "admin_role_name" {
  description = "Name of the admin IAM role."
  value       = aws_iam_role.admin.name
}

output "developer_role_arn" {
  description = "ARN of the developer IAM role."
  value       = aws_iam_role.developer.arn
}

output "developer_role_name" {
  description = "Name of the developer IAM role."
  value       = aws_iam_role.developer.name
}

output "readonly_role_arn" {
  description = "ARN of the readonly IAM role."
  value       = aws_iam_role.readonly.arn
}

output "readonly_role_name" {
  description = "Name of the readonly IAM role."
  value       = aws_iam_role.readonly.name
}

################################################################################
# Route53 Outputs
################################################################################

output "route53_zone_id" {
  description = "ID of the Route53 hosted zone."
  value       = aws_route53_zone.main.zone_id
}

output "route53_zone_name" {
  description = "Name of the Route53 hosted zone."
  value       = aws_route53_zone.main.name
}

output "route53_zone_name_servers" {
  description = "Name servers for the Route53 hosted zone."
  value       = aws_route53_zone.main.name_servers
}

################################################################################
# Account Outputs
################################################################################

output "account_id" {
  description = "AWS account ID."
  value       = data.aws_caller_identity.current.account_id
}
