terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

resource "aws_route53_zone" "zone" {
  for_each          = var.zones
  comment           = each.value.comment
  delegation_set_id = each.value.delegation_set_id
  name              = each.key
  tags              = var.tags
}
