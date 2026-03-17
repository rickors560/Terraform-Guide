locals {
  name_prefix = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
      Team        = var.team
      CostCenter  = var.cost_center
      Repository  = var.repository
    },
    var.additional_tags,
  )

  # Build assume role policy from components if custom policy is not provided
  service_principals = length(var.trusted_services) > 0 ? [
    {
      Effect = "Allow"
      Principal = {
        Service = var.trusted_services
      }
      Action = "sts:AssumeRole"
    }
  ] : []

  account_principals = length(var.trusted_account_ids) > 0 ? [
    {
      Effect = "Allow"
      Principal = {
        AWS = [for id in var.trusted_account_ids : "arn:aws:iam::${id}:root"]
      }
      Action = "sts:AssumeRole"
    }
  ] : []

  oidc_principals = [
    for provider in var.trusted_oidc_providers : {
      Effect = "Allow"
      Principal = {
        Federated = provider.provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        (provider.condition) = {
          (provider.variable) = provider.values
        }
      }
    }
  ]

  assume_role_statements = concat(
    local.service_principals,
    local.account_principals,
    local.oidc_principals,
  )

  assume_role_policy = var.custom_assume_role_policy != null ? var.custom_assume_role_policy : jsonencode({
    Version   = "2012-10-17"
    Statement = local.assume_role_statements
  })
}
