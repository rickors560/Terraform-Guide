output "nlb_dns_name" {
  description = "NLB DNS name."
  value       = module.nlb.nlb_dns_name
}

output "nlb_arn" {
  description = "NLB ARN."
  value       = module.nlb.nlb_arn
}

output "target_group_arns" {
  description = "Target group ARNs."
  value       = module.nlb.target_group_arns
}
