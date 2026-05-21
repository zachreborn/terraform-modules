output "analyzer_id" {
  description = "The ID of the Access Analyzer."
  value       = aws_accessanalyzer_analyzer.this.id
}

output "analyzer_arn" {
  description = "The ARN of the Access Analyzer."
  value       = aws_accessanalyzer_analyzer.this.arn
}

output "analyzer_name" {
  description = "The name of the Access Analyzer."
  value       = aws_accessanalyzer_analyzer.this.analyzer_name
}

output "delegated_admin_id" {
  description = "The ID of the delegated administrator resource, if created. Null if register_delegated_admin is false."
  value       = var.register_delegated_admin ? aws_organizations_delegated_administrator.this[0].id : null
}
