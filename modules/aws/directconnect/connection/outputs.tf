output "arn" {
  description = "The ARN of the Direct Connect connection."
  value       = aws_dx_connection.this.arn
}

output "id" {
  description = "The ID of the Direct Connect connection."
  value       = aws_dx_connection.this.id
}

output "aws_device" {
  description = "The Direct Connect endpoint on which the physical connection terminates."
  value       = aws_dx_connection.this.aws_device
}

output "has_logical_redundancy" {
  description = "Indicates whether the connection supports a secondary BGP peer in the same address family."
  value       = aws_dx_connection.this.has_logical_redundancy
}

output "jumbo_frame_capable" {
  description = "Whether jumbo frames are enabled for this connection."
  value       = aws_dx_connection.this.jumbo_frame_capable
}

output "macsec_capable" {
  description = "Whether the connection supports MAC Security (MACsec)."
  value       = aws_dx_connection.this.macsec_capable
}

output "owner_account_id" {
  description = "The ID of the AWS account that owns the connection."
  value       = aws_dx_connection.this.owner_account_id
}

output "partner_name" {
  description = "The name of the AWS Direct Connect service provider (carrier) associated with the connection."
  value       = aws_dx_connection.this.partner_name
}

output "port_encryption_status" {
  description = "The MAC Security (MACsec) port link status of the connection."
  value       = aws_dx_connection.this.port_encryption_status
}
