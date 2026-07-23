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
# Direct Connect Gateway
###########################

resource "aws_dx_gateway" "this" {
  name            = var.name
  amazon_side_asn = var.amazon_side_asn
  tags            = merge(tomap({ Name = var.name }), var.tags)
}
