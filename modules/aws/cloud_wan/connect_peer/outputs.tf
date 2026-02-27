###########################
# Connect Peer Outputs
###########################
output "peer_ids" {
  description = "Map of connect peer IDs"
  value       = { for k, v in aws_networkmanager_connect_peer.this : k => v.id }
}

output "peer_arns" {
  description = "Map of connect peer ARNs"
  value       = { for k, v in aws_networkmanager_connect_peer.this : k => v.arn }
}

output "core_network_addresses" {
  description = "Map of core network addresses assigned to each peer"
  value       = { for k, v in aws_networkmanager_connect_peer.this : k => v.core_network_address }
}

output "edge_locations" {
  description = "Map of edge locations for each peer"
  value       = { for k, v in aws_networkmanager_connect_peer.this : k => v.edge_location }
}

output "peer_states" {
  description = "Map of connect peer states"
  value       = { for k, v in aws_networkmanager_connect_peer.this : k => v.state }
}

output "configurations" {
  description = "Map of connect peer configurations (BGP addresses)"
  value       = { for k, v in aws_networkmanager_connect_peer.this : k => v.configuration }
}
