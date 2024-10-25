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

locals {
  # If a record in var.records is longer than 255 characters, we split the record every 255 characters with \"\" between each 255th and 256th character.
  # See https://github.com/hashicorp/terraform-provider-aws/issues/14941 for more information
  records = [for record in var.records : replace(record, "/(.{255})/", "$1\"\"")]
}

###########################
# Module Configuration
###########################

resource "aws_route53_record" "this" {
  zone_id = var.zone_id
  name    = var.name
  type    = var.type
  ttl     = var.ttl
  records = local.records

  set_identifier  = var.set_identifier
  health_check_id = var.health_check_id

  weighted_routing_policy {
    weight = var.weighted_routing_policy_weight
  }
}
