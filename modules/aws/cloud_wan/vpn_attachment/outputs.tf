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
      id         = cgw.id
      arn        = cgw.arn
      ip_address = cgw.ip_address
      bgp_asn    = cgw.bgp_asn
      tags_all   = cgw.tags_all
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
      id              = vpn.id
      arn             = vpn.arn
      type            = vpn.type
      state           = vpn.state
      tunnel1_address = vpn.tunnel1_address
      tunnel2_address = vpn.tunnel2_address
      tags_all        = vpn.tags_all
    }
  }
}
