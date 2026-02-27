###########################
# Core Network Outputs
###########################
output "id" {
  description = "Core Network ID"
  value       = aws_networkmanager_core_network.this.id
}

output "arn" {
  description = "Core Network ARN"
  value       = aws_networkmanager_core_network.this.arn
}

output "state" {
  description = "Current state of the core network"
  value       = aws_networkmanager_core_network.this.state
}

output "edges" {
  description = "Map of core network edges by location"
  value       = aws_networkmanager_core_network.this.edges
}

output "segments" {
  description = "Map of core network segments"
  value       = aws_networkmanager_core_network.this.segments
}

output "tags_all" {
  description = "Map of tags assigned to the resource, including those inherited from the provider"
  value       = aws_networkmanager_core_network.this.tags_all
}

output "policy_document" {
  description = "Current policy document attached to the core network"
  value       = var.policy_document != null ? aws_networkmanager_core_network_policy_attachment.this[0].policy_document : null
}
