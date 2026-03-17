output "web_acl_id" {
  description = "The ID of the WAF Web ACL."
  value       = aws_wafv2_web_acl.this.id
}

output "web_acl_arn" {
  description = "The ARN of the WAF Web ACL."
  value       = aws_wafv2_web_acl.this.arn
}

output "web_acl_name" {
  description = "The name of the WAF Web ACL."
  value       = aws_wafv2_web_acl.this.name
}

output "web_acl_capacity" {
  description = "Web ACL capacity units (WCU) currently being used."
  value       = aws_wafv2_web_acl.this.capacity
}

output "ip_set_arn" {
  description = "The ARN of the IP block list set."
  value       = try(aws_wafv2_ip_set.block_list[0].arn, null)
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch log group for WAF logs."
  value       = aws_cloudwatch_log_group.waf.arn
}
