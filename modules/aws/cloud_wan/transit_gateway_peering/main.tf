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
# Transit Gateway Peering
###########################
resource "aws_networkmanager_transit_gateway_peering" "this" {
  for_each            = var.peerings
  core_network_id     = var.core_network_id
  transit_gateway_arn = each.value.transit_gateway_arn
  tags                = merge(tomap({ Name = each.key }), var.tags)
}
