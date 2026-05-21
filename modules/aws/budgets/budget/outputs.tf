output "id" {
  description = "The unique identifier of the budget (same as the budget name)."
  value       = aws_budgets_budget.this.id
}

output "arn" {
  description = "The ARN of the budget."
  value       = aws_budgets_budget.this.arn
}

output "name" {
  description = "The name of the budget."
  value       = aws_budgets_budget.this.name
}
