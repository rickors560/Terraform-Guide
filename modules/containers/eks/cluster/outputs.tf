output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.this.id
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.this.arn
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the cluster"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_version" {
  description = "Kubernetes version of the cluster"
  value       = aws_eks_cluster.this.version
}

output "cluster_security_group_id" {
  description = "Cluster security group created by EKS"
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}

output "cluster_iam_role_arn" {
  description = "ARN of the cluster IAM role"
  value       = aws_iam_role.cluster.arn
}

output "cluster_iam_role_name" {
  description = "Name of the cluster IAM role"
  value       = aws_iam_role.cluster.name
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  value       = var.enable_oidc_provider ? aws_iam_openid_connect_provider.cluster[0].arn : null
}

output "oidc_provider_url" {
  description = "URL of the OIDC provider (without https://)"
  value       = var.enable_oidc_provider ? replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "") : null
}

output "oidc_issuer" {
  description = "OIDC issuer URL of the cluster"
  value       = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "cluster_platform_version" {
  description = "Platform version of the EKS cluster"
  value       = aws_eks_cluster.this.platform_version
}
