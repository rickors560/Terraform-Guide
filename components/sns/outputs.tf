###############################################################################
# SNS Component — Outputs
###############################################################################

output "topic_arn" {
  description = "ARN of the SNS topic"
  value       = aws_sns_topic.main.arn
}

output "topic_name" {
  description = "Name of the SNS topic"
  value       = aws_sns_topic.main.name
}

output "topic_id" {
  description = "ID of the SNS topic"
  value       = aws_sns_topic.main.id
}

output "email_subscription_arns" {
  description = "ARNs of email subscriptions (pending confirmation)"
  value       = { for k, v in aws_sns_topic_subscription.email : k => v.arn }
}

output "sqs_subscription_arns" {
  description = "ARNs of SQS subscriptions"
  value       = { for k, v in aws_sns_topic_subscription.sqs : k => v.arn }
}

output "lambda_subscription_arns" {
  description = "ARNs of Lambda subscriptions"
  value       = { for k, v in aws_sns_topic_subscription.lambda : k => v.arn }
}
