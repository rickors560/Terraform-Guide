output "web_acl_arn" {
  description = "WAF Web ACL ARN."
  value       = module.waf.web_acl_arn
}

output "web_acl_capacity" {
  description = "WAF Web ACL capacity units."
  value       = module.waf.web_acl_capacity
}
