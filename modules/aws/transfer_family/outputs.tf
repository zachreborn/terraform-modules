###########################
# Resource Outputs
###########################

output "server_arn" {
  description = "The ARN of the transfer family server"
  value       = aws_transfer_server.server.arn
}

output "server_endpoint" {
  description = "The endpoint of the transfer family server"
  value       = aws_transfer_server.server.endpoint
}

output "server_host_key_fingerprint" {
  description = "The RSA private key fingerprint of the transfer family server"
  value       = aws_transfer_server.server.host_key_fingerprint
}

output "server_id" {
  description = "The ID of the transfer family server"
  value       = aws_transfer_server.server.id
}
