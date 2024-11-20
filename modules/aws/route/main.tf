terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

resource "aws_route" "route" {
  carrier_gateway_id          = var.carrier_gateway_id
  count                       = length(flatten(var.route_table_ids))
  destination_cidr_block      = var.destination_cidr_block
  destination_ipv6_cidr_block = var.destination_ipv6_cidr_block
  egress_only_gateway_id      = var.egress_only_gateway_id
  gateway_id                  = var.gateway_id
  local_gateway_id            = var.local_gateway_id
  nat_gateway_id              = var.nat_gateway_id
  network_interface_id        = var.network_interface_id
  transit_gateway_id          = var.transit_gateway_id
  route_table_id              = element(flatten(var.route_table_ids), count.index)
  vpc_endpoint_id             = var.vpc_endpoint_id
  vpc_peering_connection_id   = var.vpc_peering_connection_id
}
