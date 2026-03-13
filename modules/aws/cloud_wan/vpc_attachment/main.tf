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
# VPC Attachments
###########################
resource "aws_networkmanager_vpc_attachment" "this" {
  for_each             = var.vpc_attachments
  core_network_id      = var.core_network_id
  subnet_arns          = each.value.subnet_arns
  vpc_arn              = each.value.vpc_arn
  routing_policy_label = each.value.routing_policy_label
  tags                 = merge(tomap({ Name = each.key }), var.tags)

  options {
    appliance_mode_support = each.value.appliance_mode_support
    ipv6_support           = each.value.ipv6_support
  }
}
