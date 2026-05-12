###########################
# Provider Configuration
###########################
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
# Connect Peers
###########################
resource "aws_networkmanager_connect_peer" "this" {
  for_each              = var.peers
  connect_attachment_id = var.connect_attachment_id
  peer_address          = each.value.peer_address

  bgp_options {
    peer_asn = each.value.bgp_asn
  }

  core_network_address = each.value.core_network_address
  inside_cidr_blocks   = each.value.inside_cidr_blocks
  subnet_arn           = each.value.subnet_arn

  tags = merge(tomap({ Name = each.key }), var.tags)
}
