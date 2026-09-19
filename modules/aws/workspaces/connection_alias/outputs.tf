output "ids" {
  description = "Map of WorkSpaces connection alias IDs, keyed by the same keys as var.connection_aliases."
  value       = { for k, v in aws_workspaces_connection_alias.this : k => v.id }
}

output "owner_account_ids" {
  description = "Map of the AWS account IDs that own each connection alias, keyed by the same keys as var.connection_aliases."
  value       = { for k, v in aws_workspaces_connection_alias.this : k => v.owner_account_id }
}

output "states" {
  description = "Map of the current state of each connection alias, keyed by the same keys as var.connection_aliases."
  value       = { for k, v in aws_workspaces_connection_alias.this : k => v.state }
}
