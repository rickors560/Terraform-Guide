# -----------------------------------------------------------------------------
# SES Component - Outputs
# -----------------------------------------------------------------------------

output "domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = aws_ses_domain_identity.main.arn
}

output "domain_name" {
  description = "Verified SES domain name"
  value       = aws_ses_domain_identity.main.domain
}

output "verification_token" {
  description = "Domain verification token (for manual DNS setup if not using Route53)"
  value       = aws_ses_domain_identity.main.verification_token
}

output "dkim_tokens" {
  description = "DKIM tokens for DNS configuration"
  value       = aws_ses_domain_dkim.main.dkim_tokens
}

output "configuration_set_name" {
  description = "Name of the SES configuration set"
  value       = aws_ses_configuration_set.main.name
}

output "ses_events_topic_arn" {
  description = "ARN of the SNS topic for SES events"
  value       = aws_sns_topic.ses_events.arn
}

output "welcome_template_name" {
  description = "Name of the welcome email template"
  value       = aws_ses_template.welcome.name
}

output "password_reset_template_name" {
  description = "Name of the password reset email template"
  value       = aws_ses_template.password_reset.name
}

output "notification_template_name" {
  description = "Name of the notification email template"
  value       = aws_ses_template.notification.name
}

output "mail_from_domain" {
  description = "Mail From domain for SES"
  value       = aws_ses_domain_mail_from.main.mail_from_domain
}
