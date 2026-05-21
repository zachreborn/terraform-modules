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
# Managed Prefix List
###########################
resource "aws_ec2_managed_prefix_list" "this" {
  address_family = var.address_family
  max_entries    = var.max_entries
  name           = var.name
  tags           = merge(tomap({ Name = var.name }), var.tags)

  dynamic "entry" {
    for_each = var.entries
    content {
      cidr        = entry.value.cidr
      description = lookup(entry.value, "description", null)
    }
  }
}
