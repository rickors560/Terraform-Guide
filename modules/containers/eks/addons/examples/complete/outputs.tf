output "addon_versions" {
  description = "Installed addon versions"
  value       = module.eks_addons.addon_versions
}
