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
# Private Virtual Interface
###########################

resource "aws_dx_private_virtual_interface" "this" {
  count            = var.vif_type == "private" ? 1 : 0
  connection_id    = var.dx_connection_id
  name             = var.vif_name
  vlan             = var.vlan
  bgp_asn          = var.customer_bgp_asn
  customer_address = var.customer_address
  amazon_address   = var.amazon_address
  address_family   = var.address_family
  vpn_gateway_id   = var.vpn_gateway_id
  tags             = merge(tomap({ Name = var.vif_name }), var.tags)
}

###########################
# Public Virtual Interface
###########################

resource "aws_dx_public_virtual_interface" "this" {
  count                 = var.vif_type == "public" ? 1 : 0
  connection_id         = var.dx_connection_id
  name                  = var.vif_name
  vlan                  = var.vlan
  bgp_asn               = var.customer_bgp_asn
  customer_address      = var.customer_address
  amazon_address        = var.amazon_address
  address_family        = var.address_family
  route_filter_prefixes = var.route_filter_prefixes
  tags                  = merge(tomap({ Name = var.vif_name }), var.tags)
}

###########################
# Transit Virtual Interface
###########################

resource "aws_dx_transit_virtual_interface" "this" {
  count            = var.vif_type == "transit" ? 1 : 0
  connection_id    = var.dx_connection_id
  name             = var.vif_name
  vlan             = var.vlan
  bgp_asn          = var.customer_bgp_asn
  customer_address = var.customer_address
  amazon_address   = var.amazon_address
  address_family   = var.address_family
  dx_gateway_id    = var.direct_connect_gateway_id
  tags             = merge(tomap({ Name = var.vif_name }), var.tags)
}
