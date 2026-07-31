###########################
# Customer Gateway Outputs
###########################

output "customer_gateway_ids" {
  description = "Map of customer gateway IDs, keyed by customer gateway name."
  value       = { for k, v in aws_customer_gateway.this : k => v.id }
}

output "customer_gateways" {
  description = "Map of customer gateway details, keyed by customer gateway name."
  value = {
    for k, v in aws_customer_gateway.this : k => {
      id               = v.id
      arn              = v.arn
      ip_address       = v.ip_address
      bgp_asn          = v.bgp_asn
      bgp_asn_extended = v.bgp_asn_extended
      device_name      = v.device_name
      tags_all         = v.tags_all
    }
  }
}

###########################
# VPN Connection Outputs
###########################

output "vpn_connection_ids" {
  description = "Map of VPN connection IDs, keyed by customer gateway name."
  value       = { for k, v in aws_vpn_connection.this : k => v.id }
}

output "vpn_connections" {
  description = "Map of VPN connection details, keyed by customer gateway name."
  value = {
    for k, v in aws_vpn_connection.this : k => {
      id                         = v.id
      arn                        = v.arn
      type                       = v.type
      tunnel1_address            = v.tunnel1_address
      tunnel2_address            = v.tunnel2_address
      tunnel1_bgp_asn            = v.tunnel1_bgp_asn
      tunnel2_bgp_asn            = v.tunnel2_bgp_asn
      tunnel1_bgp_holdtime       = v.tunnel1_bgp_holdtime
      tunnel2_bgp_holdtime       = v.tunnel2_bgp_holdtime
      tunnel1_cgw_inside_address = v.tunnel1_cgw_inside_address
      tunnel2_cgw_inside_address = v.tunnel2_cgw_inside_address
      tunnel1_vgw_inside_address = v.tunnel1_vgw_inside_address
      tunnel2_vgw_inside_address = v.tunnel2_vgw_inside_address
      tags_all                   = v.tags_all
    }
  }
}

###########################
# Cloud WAN Attachment Outputs
###########################

output "cloud_wan_attachment_ids" {
  description = "Map of Cloud WAN Site-to-Site VPN attachment IDs, keyed by customer gateway name (empty when create_cloud_wan_attachment is false)."
  value       = { for k, v in aws_networkmanager_site_to_site_vpn_attachment.this : k => v.id }
}

output "cloud_wan_attachments" {
  description = "Map of Cloud WAN Site-to-Site VPN attachment details, keyed by customer gateway name (empty when create_cloud_wan_attachment is false)."
  value = {
    for k, v in aws_networkmanager_site_to_site_vpn_attachment.this : k => {
      id               = v.id
      arn              = v.arn
      attachment_type  = v.attachment_type
      core_network_arn = v.core_network_arn
      edge_location    = v.edge_location
      segment_name     = v.segment_name
      state            = v.state
      tags_all         = v.tags_all
    }
  }
}
