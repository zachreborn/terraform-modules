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
# Transit Virtual Interface
###########################
# Transit VIFs connect to a Direct Connect Gateway, which can then be associated
# with Transit Gateways or Cloud WAN core networks. Transit VIFs support MTU up
# to 8500 (jumbo frames) and are required for multi-account or multi-VPC routing.

resource "aws_dx_transit_virtual_interface" "this" {
  connection_id    = var.connection_id
  dx_gateway_id    = var.dx_gateway_id
  name             = var.name
  vlan             = var.vlan
  address_family   = var.address_family
  bgp_asn          = var.bgp_asn
  amazon_address   = var.amazon_address
  customer_address = var.customer_address
  bgp_auth_key     = var.bgp_auth_key
  mtu              = var.mtu
  sitelink_enabled = var.sitelink_enabled
  tags             = merge(tomap({ Name = var.name }), var.tags)
}
