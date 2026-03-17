output "node_group_id" {
  description = "ID of the EKS node group"
  value       = aws_eks_node_group.this.id
}

output "node_group_arn" {
  description = "ARN of the EKS node group"
  value       = aws_eks_node_group.this.arn
}

output "node_group_name" {
  description = "Name of the EKS node group"
  value       = aws_eks_node_group.this.node_group_name
}

output "node_group_status" {
  description = "Status of the EKS node group"
  value       = aws_eks_node_group.this.status
}

output "node_role_arn" {
  description = "ARN of the node IAM role"
  value       = aws_iam_role.node.arn
}

output "node_role_name" {
  description = "Name of the node IAM role"
  value       = aws_iam_role.node.name
}
