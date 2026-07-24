###########################################################
# AWS Organization Delegated Administrator
###########################################################

output "delegated_administrator_ids" {
  description = "Map of delegated administrator instance IDs keyed by '<logical_key>-<service_principal>' (e.g. 'backups-backup.amazonaws.com'). Each value is the resource ID in the form '<account_id>/<service_principal>'."
  value       = { for k, v in aws_organizations_delegated_administrator.this : k => v.id }
}

output "delegated_administrators" {
  description = "Map of full delegated administrator resource objects keyed by '<logical_key>-<service_principal>'. Each object exposes account_id, service_principal, arn, name, email, status, joined_method, joined_timestamp, and delegation_enabled_date."
  value       = { for k, v in aws_organizations_delegated_administrator.this : k => v }
}
