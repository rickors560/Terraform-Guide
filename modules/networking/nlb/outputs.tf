output "nlb_id" {
  description = "The ID of the NLB."
  value       = aws_lb.this.id
}

output "nlb_arn" {
  description = "The ARN of the NLB."
  value       = aws_lb.this.arn
}

output "nlb_arn_suffix" {
  description = "The ARN suffix of the NLB for use with CloudWatch Metrics."
  value       = aws_lb.this.arn_suffix
}

output "nlb_dns_name" {
  description = "The DNS name of the NLB."
  value       = aws_lb.this.dns_name
}

output "nlb_zone_id" {
  description = "The canonical hosted zone ID of the NLB (for Route53 alias records)."
  value       = aws_lb.this.zone_id
}

output "target_group_arns" {
  description = "List of target group ARNs."
  value       = aws_lb_target_group.this[*].arn
}

output "target_group_arn_suffixes" {
  description = "List of target group ARN suffixes."
  value       = aws_lb_target_group.this[*].arn_suffix
}

output "target_group_names" {
  description = "List of target group names."
  value       = aws_lb_target_group.this[*].name
}

output "listener_arns" {
  description = "List of listener ARNs."
  value       = aws_lb_listener.this[*].arn
}
