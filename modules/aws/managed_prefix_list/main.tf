###########################
# Provider Configuration
###########################
terraform {
  # >= 1.3.0 is required because variables.tf uses optional() attributes in the
  # `entries` object type constraint.
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Managed Prefix List
###########################
resource "aws_ec2_managed_prefix_list" "this" {
  address_family = var.address_family
  max_entries    = var.max_entries
  name           = var.name
  region         = var.region
  tags           = merge(tomap({ Name = var.name }), var.tags)

  dynamic "entry" {
    for_each = var.entries
    content {
      cidr        = entry.value.cidr
      description = entry.value.description
    }
  }
}
