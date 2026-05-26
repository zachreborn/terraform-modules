terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

resource "aws_ec2_transit_gateway_route" "this" {
  for_each                       = toset(var.destination_cidr_blocks)
  blackhole                      = var.blackhole
  destination_cidr_block         = each.key
  transit_gateway_attachment_id  = var.transit_gateway_attachment_id
  transit_gateway_route_table_id = var.transit_gateway_route_table_id
}
