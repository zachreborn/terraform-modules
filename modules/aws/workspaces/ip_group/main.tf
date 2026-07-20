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
# WorkSpaces IP Access Control Groups
###########################

resource "aws_workspaces_ip_group" "this" {
  for_each = var.ip_groups

  name        = coalesce(each.value.name, each.key)
  description = each.value.description
  region      = each.value.region
  tags        = merge(tomap({ Name = coalesce(each.value.name, each.key) }), var.tags, each.value.tags)

  dynamic "rules" {
    for_each = each.value.rules
    content {
      source      = rules.value.source
      description = rules.value.description
    }
  }
}
