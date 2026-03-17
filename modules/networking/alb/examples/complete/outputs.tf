output "alb_dns_name" {
  description = "ALB DNS name."
  value       = module.alb.alb_dns_name
}

output "alb_arn" {
  description = "ALB ARN."
  value       = module.alb.alb_arn
}

output "target_group_arn" {
  description = "Default target group ARN."
  value       = module.alb.target_group_arn
}
