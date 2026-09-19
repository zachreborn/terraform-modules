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
# WorkSpaces Connection Aliases
###########################

resource "aws_workspaces_connection_alias" "this" {
  for_each = var.connection_aliases

  connection_string = each.value.connection_string
  region            = each.value.region
  tags              = merge(tomap({ Name = each.key }), var.tags, each.value.tags)
}
