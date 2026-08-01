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
    aws_dx_private_virtual_interface.this[0].bgp_asn,
    aws_dx_public_virtual_interface.this[0].bgp_asn,
    aws_dx_transit_virtual_interface.this[0].bgp_asn,
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

output "mtu" {
  description = "The maximum transmission unit (MTU) of the VIF, in bytes. Only applicable to private/transit VIFs."
  value = try(
    aws_dx_private_virtual_interface.this[0].mtu,
    aws_dx_transit_virtual_interface.this[0].mtu,
    null
  )
}

output "sitelink_enabled" {
  description = "Whether AWS Direct Connect SiteLink is enabled for the VIF. Only applicable to private/transit VIFs."
  value = try(
    aws_dx_private_virtual_interface.this[0].sitelink_enabled,
    aws_dx_transit_virtual_interface.this[0].sitelink_enabled,
    null
  )
}

output "amazon_side_asn" {
  description = "The autonomous system (AS) number for the Amazon side of the BGP session."
  value = try(
    aws_dx_private_virtual_interface.this[0].amazon_side_asn,
    aws_dx_public_virtual_interface.this[0].amazon_side_asn,
    aws_dx_transit_virtual_interface.this[0].amazon_side_asn,
    null
  )
}
