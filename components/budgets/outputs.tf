# -----------------------------------------------------------------------------
# Budgets Component - Outputs
# -----------------------------------------------------------------------------

output "monthly_cost_budget_id" {
  description = "ID of the monthly cost budget"
  value       = aws_budgets_budget.monthly_cost.id
}

output "monthly_cost_budget_name" {
  description = "Name of the monthly cost budget"
  value       = aws_budgets_budget.monthly_cost.name
}

output "ec2_budget_id" {
  description = "ID of the EC2 service budget"
  value       = aws_budgets_budget.ec2.id
}

output "rds_budget_id" {
  description = "ID of the RDS service budget"
  value       = aws_budgets_budget.rds.id
}

output "data_transfer_budget_id" {
  description = "ID of the data transfer budget"
  value       = aws_budgets_budget.data_transfer.id
}
