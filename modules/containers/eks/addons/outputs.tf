output "addon_ids" {
  description = "Map of addon name to addon ID"
  value       = { for k, v in aws_eks_addon.this : k => v.id }
}

output "addon_arns" {
  description = "Map of addon name to addon ARN"
  value       = { for k, v in aws_eks_addon.this : k => v.arn }
}

output "addon_versions" {
  description = "Map of addon name to installed version"
  value       = { for k, v in aws_eks_addon.this : k => v.addon_version }
}
