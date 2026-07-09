output "ids" {
  description = "Map of WorkSpaces desktop IDs, keyed by the same keys as var.workspaces."
  value       = { for k, v in aws_workspaces_workspace.this : k => v.id }
}

output "ip_addresses" {
  description = "Map of WorkSpaces desktop IP addresses, keyed by the same keys as var.workspaces."
  value       = { for k, v in aws_workspaces_workspace.this : k => v.ip_address }
}

output "computer_names" {
  description = "Map of WorkSpaces desktop computer names (as seen by the operating system), keyed by the same keys as var.workspaces."
  value       = { for k, v in aws_workspaces_workspace.this : k => v.computer_name }
}

output "states" {
  description = "Map of WorkSpaces desktop operational states, keyed by the same keys as var.workspaces."
  value       = { for k, v in aws_workspaces_workspace.this : k => v.state }
}

output "bundle_ids" {
  description = "Map of the resolved WorkSpaces bundle ID used for each desktop (whichever of bundle_id or a bundle_name/bundle_owner lookup resolved it), keyed by the same keys as var.workspaces."
  value       = local.resolved_bundle_ids
}

output "kms_key_arn" {
  description = "ARN of the shared default KMS key created for volume encryption, or null when enable_default_kms_key is false or no entry needed it."
  value       = try(module.default_kms_key["this"].arn, null)
}
