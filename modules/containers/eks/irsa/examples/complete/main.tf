provider "aws" {
  region = var.aws_region
}

module "irsa" {
  source = "../../"

  project     = var.project
  environment = var.environment

  role_name_suffix     = "ebs-csi-driver"
  oidc_provider_arn    = var.oidc_provider_arn
  oidc_provider_url    = var.oidc_provider_url
  namespace            = "kube-system"
  service_account_name = "ebs-csi-controller-sa"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  ]

  team        = var.team
  cost_center = var.cost_center
  repository  = var.repository
}
