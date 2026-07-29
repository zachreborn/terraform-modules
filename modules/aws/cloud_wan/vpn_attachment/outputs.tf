###########################
# Customer Gateway Outputs
###########################

output "customer_gateway_ids" {
  description = "IDs of the created customer gateways."
  value       = aws_customer_gateway.this[*].id
}

output "customer_gateways" {
  description = "Map of customer gateway details."
  value = {
    for idx, cgw in aws_customer_gateway.this :
    var.customer_gateways[idx].name => {
      id               = cgw.id
      arn              = cgw.arn
      ip_address       = cgw.ip_address
      bgp_asn          = cgw.bgp_asn
      bgp_asn_extended = cgw.bgp_asn_extended
      device_name      = cgw.device_name
      tags_all         = cgw.tags_all
    }
  }
}

###########################
# VPN Connection Outputs
###########################

output "vpn_connection_ids" {
  description = "IDs of the created VPN connections."
  value       = aws_vpn_connection.this[*].id
}

output "vpn_connections" {
  description = "Map of VPN connection details."
  value = {
    for idx, vpn in aws_vpn_connection.this :
    var.customer_gateways[idx].name => {
      id                         = vpn.id
      arn                        = vpn.arn
      type                       = vpn.type
      state                      = vpn.state
      tunnel1_address            = vpn.tunnel1_address
      tunnel2_address            = vpn.tunnel2_address
      tunnel1_bgp_asn            = vpn.tunnel1_bgp_asn
      tunnel2_bgp_asn            = vpn.tunnel2_bgp_asn
      tunnel1_bgp_holdtime       = vpn.tunnel1_bgp_holdtime
      tunnel2_bgp_holdtime       = vpn.tunnel2_bgp_holdtime
      tunnel1_cgw_inside_address = vpn.tunnel1_cgw_inside_address
      tunnel2_cgw_inside_address = vpn.tunnel2_cgw_inside_address
      tunnel1_vgw_inside_address = vpn.tunnel1_vgw_inside_address
      tunnel2_vgw_inside_address = vpn.tunnel2_vgw_inside_address
      tags_all                   = vpn.tags_all
    }
  }
}

###########################
# Cloud WAN Attachment Outputs
###########################

output "cloud_wan_attachment_ids" {
  description = "IDs of the Cloud WAN Site-to-Site VPN attachments (empty when create_cloud_wan_attachment is false)."
  value       = aws_networkmanager_site_to_site_vpn_attachment.this[*].id
}

output "cloud_wan_attachments" {
  description = "Map of Cloud WAN Site-to-Site VPN attachment details, keyed by customer gateway name (empty when create_cloud_wan_attachment is false)."
  value = {
    for idx, attachment in aws_networkmanager_site_to_site_vpn_attachment.this :
    var.customer_gateways[idx].name => {
      id               = attachment.id
      arn              = attachment.arn
      attachment_type  = attachment.attachment_type
      core_network_arn = attachment.core_network_arn
      edge_location    = attachment.edge_location
      segment_name     = attachment.segment_name
      state            = attachment.state
      tags_all         = attachment.tags_all
    }
  }
}
