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

  lifecycle {
    precondition {
      condition     = length(var.entries) <= var.max_entries
      error_message = "The number of entries (${length(var.entries)}) must not exceed max_entries (${var.max_entries}); AWS rejects a create/update once the entry count exceeds the list's capacity."
    }

    precondition {
      # A cidr is treated as IPv6-shaped when it contains a colon. AWS rejects a
      # prefix list whose entries mix address families with its address_family.
      condition = alltrue([
        for e in var.entries : can(regex(":", e.cidr)) == (var.address_family == "IPv6")
      ])
      error_message = "All entries must match address_family: IPv4 CIDRs are required when address_family is IPv4, and IPv6 CIDRs when address_family is IPv6."
    }
  }
}
