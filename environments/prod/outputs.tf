################################################################################
# VPC Outputs
################################################################################

output "vpc_id" {
  description = "ID of the VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC."
  value       = var.vpc_cidr
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets."
  value       = module.vpc.private_subnet_ids
}

output "database_subnet_ids" {
  description = "IDs of the database subnets."
  value       = module.vpc.database_subnet_ids
}

################################################################################
# EKS Outputs
################################################################################

output "eks_cluster_name" {
  description = "Name of the EKS cluster."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server."
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data for the EKS cluster."
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

################################################################################
# RDS Outputs
################################################################################

output "rds_endpoint" {
  description = "Endpoint of the RDS instance."
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "Hostname of the RDS instance."
  value       = aws_db_instance.main.address
}

output "rds_port" {
  description = "Port of the RDS instance."
  value       = aws_db_instance.main.port
}

output "rds_database_name" {
  description = "Name of the default database."
  value       = aws_db_instance.main.db_name
}

output "rds_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret containing RDS credentials."
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

################################################################################
# ElastiCache Redis Outputs
################################################################################

output "redis_configuration_endpoint" {
  description = "Configuration endpoint of the Redis cluster (cluster mode)."
  value       = aws_elasticache_replication_group.main.configuration_endpoint_address
}

output "redis_primary_endpoint" {
  description = "Primary endpoint of the Redis replication group."
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Reader endpoint of the Redis replication group."
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

output "redis_port" {
  description = "Port of the Redis replication group."
  value       = aws_elasticache_replication_group.main.port
}

################################################################################
# ALB Outputs
################################################################################

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the Application Load Balancer."
  value       = aws_lb.main.zone_id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer."
  value       = aws_lb.main.arn
}

################################################################################
# ACM Outputs
################################################################################

output "acm_certificate_arn" {
  description = "ARN of the ACM certificate."
  value       = aws_acm_certificate.main.arn
}

output "acm_certificate_domain_name" {
  description = "Domain name of the ACM certificate."
  value       = aws_acm_certificate.main.domain_name
}

################################################################################
# WAF Outputs
################################################################################

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL."
  value       = aws_wafv2_web_acl.main.arn
}

output "waf_web_acl_id" {
  description = "ID of the WAF Web ACL."
  value       = aws_wafv2_web_acl.main.id
}

################################################################################
# KMS Outputs
################################################################################

output "kms_main_key_arn" {
  description = "ARN of the main KMS key."
  value       = aws_kms_key.main.arn
}

output "kms_main_key_id" {
  description = "ID of the main KMS key."
  value       = aws_kms_key.main.key_id
}

output "kms_rds_key_arn" {
  description = "ARN of the RDS KMS key."
  value       = aws_kms_key.rds.arn
}

output "kms_s3_key_arn" {
  description = "ARN of the S3 KMS key."
  value       = aws_kms_key.s3.arn
}

################################################################################
# S3 Outputs
################################################################################

output "app_assets_bucket_name" {
  description = "Name of the app assets S3 bucket."
  value       = aws_s3_bucket.app_assets.id
}

output "app_assets_bucket_arn" {
  description = "ARN of the app assets S3 bucket."
  value       = aws_s3_bucket.app_assets.arn
}

output "cloudtrail_bucket_name" {
  description = "Name of the CloudTrail S3 bucket."
  value       = aws_s3_bucket.cloudtrail.id
}

################################################################################
# ECR Outputs
################################################################################

output "ecr_repository_urls" {
  description = "Map of ECR repository names to URLs."
  value       = { for k, v in aws_ecr_repository.repos : k => v.repository_url }
}

################################################################################
# Security Group Outputs
################################################################################

output "alb_security_group_id" {
  description = "ID of the ALB security group."
  value       = aws_security_group.alb.id
}

output "app_security_group_id" {
  description = "ID of the application security group."
  value       = aws_security_group.app.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group."
  value       = aws_security_group.rds.id
}

output "redis_security_group_id" {
  description = "ID of the Redis security group."
  value       = aws_security_group.redis.id
}

################################################################################
# Monitoring Outputs
################################################################################

output "sns_alarms_topic_arn" {
  description = "ARN of the SNS topic for CloudWatch alarms."
  value       = aws_sns_topic.alarms.arn
}

output "sns_critical_topic_arn" {
  description = "ARN of the SNS topic for critical CloudWatch alarms."
  value       = aws_sns_topic.critical.arn
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard."
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}

################################################################################
# Secrets Manager Outputs
################################################################################

output "app_secrets_arn" {
  description = "ARN of the application Secrets Manager secret."
  value       = aws_secretsmanager_secret.app_secrets.arn
}

################################################################################
# CloudTrail Outputs
################################################################################

output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail."
  value       = aws_cloudtrail.main.arn
}
