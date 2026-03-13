###########################
# Connect Attachment Outputs
###########################
output "attachment_ids" {
  description = "Map of connect attachment IDs"
  value       = { for k, v in aws_networkmanager_connect_attachment.this : k => v.id }
}

output "attachment_arns" {
  description = "Map of connect attachment ARNs"
  value       = { for k, v in aws_networkmanager_connect_attachment.this : k => v.arn }
}

output "attachment_states" {
  description = "Map of connect attachment states"
  value       = { for k, v in aws_networkmanager_connect_attachment.this : k => v.state }
}

output "attachment_types" {
  description = "Map of connect attachment types"
  value       = { for k, v in aws_networkmanager_connect_attachment.this : k => v.attachment_type }
}

output "core_network_arns" {
  description = "Map of core network ARNs for each connect attachment"
  value       = { for k, v in aws_networkmanager_connect_attachment.this : k => v.core_network_arn }
}
