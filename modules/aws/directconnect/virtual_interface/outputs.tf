###########################
# VIF Outputs
###########################

output "private_vif_id" {
  description = "The ID of the private virtual interface."
  value       = try(aws_dx_private_virtual_interface.this[0].id, null)
}

output "public_vif_id" {
  description = "The ID of the public virtual interface."
  value       = try(aws_dx_public_virtual_interface.this[0].id, null)
}

output "transit_vif_id" {
  description = "The ID of the transit virtual interface."
  value       = try(aws_dx_transit_virtual_interface.this[0].id, null)
}

output "vif_id" {
  description = "The ID of the created virtual interface."
  value = try(
    aws_dx_private_virtual_interface.this[0].id,
    aws_dx_public_virtual_interface.this[0].id,
    aws_dx_transit_virtual_interface.this[0].id,
    null
  )
}

output "bgp_asn" {
  description = "The ASN used by the customer."
  value = try(
    aws_dx_private_virtual_interface.this[0].customer_address,
    aws_dx_public_virtual_interface.this[0].customer_address,
    aws_dx_transit_virtual_interface.this[0].customer_address,
    null
  )
}

output "customer_address" {
  description = "The IPv4 CIDR address used on the customer side of the connection."
  value = try(
    aws_dx_private_virtual_interface.this[0].customer_address,
    aws_dx_public_virtual_interface.this[0].customer_address,
    aws_dx_transit_virtual_interface.this[0].customer_address,
    null
  )
}

output "amazon_address" {
  description = "The IPv4 CIDR address used on the Amazon side of the connection."
  value = try(
    aws_dx_private_virtual_interface.this[0].amazon_address,
    aws_dx_public_virtual_interface.this[0].amazon_address,
    aws_dx_transit_virtual_interface.this[0].amazon_address,
    null
  )
}

output "tags_all" {
  description = "A map of tags assigned to the VIF."
  value = try(
    aws_dx_private_virtual_interface.this[0].tags_all,
    aws_dx_public_virtual_interface.this[0].tags_all,
    aws_dx_transit_virtual_interface.this[0].tags_all,
    null
  )
}
