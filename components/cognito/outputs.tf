# -----------------------------------------------------------------------------
# Cognito Component - Outputs
# -----------------------------------------------------------------------------

output "user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Endpoint of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.endpoint
}

output "user_pool_domain" {
  description = "Domain of the Cognito User Pool"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "web_client_id" {
  description = "ID of the web app client"
  value       = aws_cognito_user_pool_client.web.id
}

output "server_client_id" {
  description = "ID of the server app client"
  value       = aws_cognito_user_pool_client.server.id
}

output "identity_pool_id" {
  description = "ID of the Cognito Identity Pool"
  value       = aws_cognito_identity_pool.main.id
}

output "admin_group_name" {
  description = "Name of the admin user group"
  value       = aws_cognito_user_group.admin.name
}

output "editor_group_name" {
  description = "Name of the editor user group"
  value       = aws_cognito_user_group.editor.name
}

output "viewer_group_name" {
  description = "Name of the viewer user group"
  value       = aws_cognito_user_group.viewer.name
}

output "authenticated_role_arn" {
  description = "ARN of the authenticated user IAM role"
  value       = aws_iam_role.cognito_authenticated.arn
}

output "hosted_ui_url" {
  description = "URL of the Cognito Hosted UI"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.region}.amazoncognito.com"
}
