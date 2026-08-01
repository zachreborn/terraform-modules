###########################
# Connection Outputs
###########################

output "id" {
  description = "The ID of the Direct Connect connection."
  value       = aws_dx_connection.this.id
}

output "arn" {
  description = "The ARN of the Direct Connect connection."
  value       = aws_dx_connection.this.arn
}

output "name" {
  description = "The name of the Direct Connect connection."
  value       = aws_dx_connection.this.name
}

output "location" {
  description = "The location of the Direct Connect connection."
  value       = aws_dx_connection.this.location
}

output "bandwidth" {
  description = "The bandwidth of the Direct Connect connection."
  value       = aws_dx_connection.this.bandwidth
}

output "has_logical_redundancy" {
  description = "Indicates whether the connection has logical redundancy."
  value       = aws_dx_connection.this.has_logical_redundancy
}

output "jumbo_frame_capable" {
  description = "Boolean value indicating whether jumbo frames (9000 MTU) are supported."
  value       = aws_dx_connection.this.jumbo_frame_capable
}

output "aws_device" {
  description = "The Direct Connect endpoint on which the physical connection terminates."
  value       = aws_dx_connection.this.aws_device
}

output "owner_account_id" {
  description = "The ID of the AWS account that owns the connection."
  value       = aws_dx_connection.this.owner_account_id
}

output "partner_name" {
  description = "The name of the AWS Direct Connect service provider associated with the connection."
  value       = aws_dx_connection.this.partner_name
}

output "provider_name" {
  description = "The name of the service provider associated with the connection."
  value       = aws_dx_connection.this.provider_name
}

output "vlan_id" {
  description = "The VLAN ID of the connection."
  value       = aws_dx_connection.this.vlan_id
}

output "macsec_capable" {
  description = "Boolean value indicating whether the connection supports MACsec."
  value       = aws_dx_connection.this.macsec_capable
}

output "port_encryption_status" {
  description = "The MACsec port link status of the connection."
  value       = aws_dx_connection.this.port_encryption_status
}

output "encryption_mode" {
  description = "The MACsec encryption mode of the connection."
  value       = aws_dx_connection.this.encryption_mode
}

output "tags_all" {
  description = "A map of tags assigned to the resource, including those inherited from the provider default_tags configuration block."
  value       = aws_dx_connection.this.tags_all
}
