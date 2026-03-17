output "topic_arn" {
  description = "ARN of the SNS topic."
  value       = module.sns_pubsub.topic_arn
}

output "topic_name" {
  description = "Name of the SNS topic."
  value       = module.sns_pubsub.topic_name
}

output "subscription_arns" {
  description = "Map of subscription ARNs."
  value       = module.sns_pubsub.subscription_arns
}
