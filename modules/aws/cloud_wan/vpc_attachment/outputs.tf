###########################
# VPC Attachment Outputs
###########################
output "attachment_ids" {
  description = "Map of VPC attachment IDs"
  value       = { for k, v in aws_networkmanager_vpc_attachment.this : k => v.id }
}

output "attachment_arns" {
  description = "Map of VPC attachment ARNs"
  value       = { for k, v in aws_networkmanager_vpc_attachment.this : k => v.arn }
}

output "edge_locations" {
  description = "Map of VPC attachment edge locations"
  value       = { for k, v in aws_networkmanager_vpc_attachment.this : k => v.edge_location }
}

output "segment_names" {
  description = "Map of VPC attachment segment names"
  value       = { for k, v in aws_networkmanager_vpc_attachment.this : k => v.segment_name }
}

output "attachment_states" {
  description = "Map of VPC attachment states"
  value       = { for k, v in aws_networkmanager_vpc_attachment.this : k => v.state }
}
