###########################
# Resource Outputs
###########################
output "global_network_arn" {
  description = "ARN of the global network"
  value       = aws_networkmanager_global_network.this.arn
}
