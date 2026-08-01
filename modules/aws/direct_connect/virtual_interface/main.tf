terraform {
  # >= 1.2.0 is required for the lifecycle.precondition blocks used below to validate
  # conditional required arguments per vif_type.
  required_version = ">= 1.2.0"
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
  dx_gateway_id    = var.direct_connect_gateway_id
  mtu              = var.mtu
  sitelink_enabled = var.sitelink_enabled
  bgp_auth_key     = var.bgp_auth_key
  tags             = merge(tomap({ Name = var.vif_name }), var.tags)

  lifecycle {
    precondition {
      condition     = var.vpn_gateway_id != null || var.direct_connect_gateway_id != null
      error_message = "vif_type \"private\" requires either vpn_gateway_id or direct_connect_gateway_id to be set."
    }
    precondition {
      condition     = !(var.vpn_gateway_id != null && var.direct_connect_gateway_id != null)
      error_message = "vif_type \"private\" accepts only one of vpn_gateway_id or direct_connect_gateway_id, not both."
    }
  }
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
  bgp_auth_key          = var.bgp_auth_key
  tags                  = merge(tomap({ Name = var.vif_name }), var.tags)

  lifecycle {
    precondition {
      condition     = length(var.route_filter_prefixes) > 0
      error_message = "vif_type \"public\" requires at least one entry in route_filter_prefixes."
    }
  }
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
  mtu              = var.mtu
  sitelink_enabled = var.sitelink_enabled
  bgp_auth_key     = var.bgp_auth_key
  tags             = merge(tomap({ Name = var.vif_name }), var.tags)

  lifecycle {
    precondition {
      condition     = var.direct_connect_gateway_id != null
      error_message = "vif_type \"transit\" requires direct_connect_gateway_id to be set."
    }
  }
}
