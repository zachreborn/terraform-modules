terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Customer Gateway
###########################

resource "aws_customer_gateway" "this" {
  count           = length(var.customer_gateways)
  bgp_asn         = var.customer_gateways[count.index].bgp_asn
  certificate_arn = try(var.customer_gateways[count.index].certificate_arn, null)
  ip_address      = var.customer_gateways[count.index].ip_address
  type            = "ipsec.1"
  tags            = merge(tomap({ Name = var.customer_gateways[count.index].name }), var.tags)
}

###########################
# Site-to-Site VPN Connection
###########################

resource "aws_vpn_connection" "this" {
  count               = length(var.customer_gateways)
  customer_gateway_id = aws_customer_gateway.this[count.index].id
  static_routes_only  = var.static_routes_only
  type                = "ipsec.1"

  tunnel1_ike_versions                 = var.tunnel_ike_versions
  tunnel2_ike_versions                 = var.tunnel_ike_versions
  tunnel1_phase1_dh_group_numbers      = var.tunnel_phase1_dh_group_numbers
  tunnel2_phase1_dh_group_numbers      = var.tunnel_phase1_dh_group_numbers
  tunnel1_phase1_encryption_algorithms = var.tunnel_phase1_encryption_algorithms
  tunnel2_phase1_encryption_algorithms = var.tunnel_phase1_encryption_algorithms
  tunnel1_phase1_integrity_algorithms  = var.tunnel_phase1_integrity_algorithms
  tunnel2_phase1_integrity_algorithms  = var.tunnel_phase1_integrity_algorithms
  tunnel1_phase2_dh_group_numbers      = var.tunnel_phase2_dh_group_numbers
  tunnel2_phase2_dh_group_numbers      = var.tunnel_phase2_dh_group_numbers
  tunnel1_phase2_encryption_algorithms = var.tunnel_phase2_encryption_algorithms
  tunnel2_phase2_encryption_algorithms = var.tunnel_phase2_encryption_algorithms
  tunnel1_phase2_integrity_algorithms  = var.tunnel_phase2_integrity_algorithms
  tunnel2_phase2_integrity_algorithms  = var.tunnel_phase2_integrity_algorithms
  tunnel1_startup_action               = var.tunnel_startup_action
  tunnel2_startup_action               = var.tunnel_startup_action

  tags = merge(tomap({ Name = "${var.customer_gateways[count.index].name}-vpn" }), var.tags)
}
