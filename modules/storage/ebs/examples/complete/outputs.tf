output "volume_id" {
  description = "EBS volume ID"
  value       = module.ebs.volume_id
}

output "volume_arn" {
  description = "EBS volume ARN"
  value       = module.ebs.volume_arn
}
