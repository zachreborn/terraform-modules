###########################
# Transit Gateway Peering Outputs
###########################
output "peering_ids" {
  description = "Map of peering IDs"
  value       = { for k, v in aws_networkmanager_transit_gateway_peering.this : k => v.id }
}

output "peering_arns" {
  description = "Map of peering ARNs"
  value       = { for k, v in aws_networkmanager_transit_gateway_peering.this : k => v.arn }
}

output "attachment_ids" {
  description = "Map of transit gateway peering attachment IDs"
  value       = { for k, v in aws_networkmanager_transit_gateway_peering.this : k => v.transit_gateway_peering_attachment_id }
}

output "edge_locations" {
  description = "Map of edge locations for each peering"
  value       = { for k, v in aws_networkmanager_transit_gateway_peering.this : k => v.edge_location }
}

output "core_network_arns" {
  description = "Map of core network ARNs"
  value       = { for k, v in aws_networkmanager_transit_gateway_peering.this : k => v.core_network_arn }
}
