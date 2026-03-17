output "node_group_name" {
  description = "Node group name"
  value       = module.node_group.node_group_name
}

output "node_role_arn" {
  description = "Node IAM role ARN"
  value       = module.node_group.node_role_arn
}
