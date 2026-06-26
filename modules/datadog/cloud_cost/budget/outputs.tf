###########################
# Resource Outputs
###########################

output "ids" {
  description = "Map of logical names to the IDs of the cost budgets."
  value       = { for k, v in datadog_cost_budget.this : k => v.id }
}

output "total_amounts" {
  description = "Map of logical names to the total amount (sum of all budget entries) for each budget."
  value       = { for k, v in datadog_cost_budget.this : k => v.total_amount }
}
