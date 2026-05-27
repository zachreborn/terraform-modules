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

output "tags_all" {
  description = "A map of tags assigned to the resource, including those inherited from the provider default_tags configuration block."
  value       = aws_budgets_budget.this.tags_all
}
