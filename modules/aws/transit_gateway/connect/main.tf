terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

##################################
# Transit Gateway Connect Attachment
##################################
resource "aws_ec2_transit_gateway_connect" "connect_attachment" {
  protocol                                        = var.protocol
  tags                                            = merge(tomap({ Name = var.name }), var.tags)
  transit_gateway_default_route_table_association = var.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = var.transit_gateway_default_route_table_propagation
  transport_attachment_id                         = var.transport_attachment_id
  transit_gateway_id                              = var.transit_gateway_id
}

##################################
# Transit Gateway Connect Peer
##################################
resource "aws_ec2_transit_gateway_connect_peer" "peer" {
  for_each                      = var.peers
  bgp_asn                       = each.value.bgp_asn
  inside_cidr_blocks            = each.value.inside_cidr_blocks
  peer_address                  = each.value.peer_address
  tags                          = merge(tomap({ Name = each.key }), var.tags)
  transit_gateway_attachment_id = aws_ec2_transit_gateway_connect.connect_attachment.id
  transit_gateway_address       = each.value.transit_gateway_address
}
