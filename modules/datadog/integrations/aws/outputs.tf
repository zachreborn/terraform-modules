###########################
# Resource Outputs
###########################
output "aws_account_ids" {
  description = "Map of AWS account integration IDs keyed by logical name (covers both role-based and key-based auth accounts)."
  value = merge(
    { for k, v in datadog_integration_aws_account.role : k => v.id },
    { for k, v in datadog_integration_aws_account.keys : k => v.id }
  )
}

output "external_ids" {
  description = "Map of Datadog-generated AWS IAM external IDs keyed by logical name. Only populated for accounts where create_external_id = true. Use these values in the IAM role trust policy."
  value       = { for k, v in datadog_integration_aws_external_id.this : k => v.id }
  sensitive   = true
}
