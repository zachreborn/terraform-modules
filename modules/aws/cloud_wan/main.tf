###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

###########################
# Data Sources
###########################


###########################
# Locals
###########################

###########################
# Module Configuration
###########################

resource "aws_networkmanager_global_network" "this" {
  description = var.description
  tags        = var.tags
}

# resource "aws_networkmanager_core_network" "this" {
#   base_policy_regions = var.base_policy_regions
#   description         = var.description
#   global_network_id   = aws_networkmanager_global_network.this.id
#   tags                = var.tags
# }

###########################
# Transit Gateway
###########################

resource "aws_networkmanager_transit_gateway_registration" "this" {
  for_each            = toset(var.transit_gateway_arns)
  global_network_id   = aws_networkmanager_global_network.this.id
  transit_gateway_arn = each.key
}
