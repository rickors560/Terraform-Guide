output "budget_ids" {
  description = "Map of budget names to IDs."
  value       = module.budgets.budget_ids
}

output "budget_arns" {
  description = "Map of budget names to ARNs."
  value       = module.budgets.budget_arns
}
