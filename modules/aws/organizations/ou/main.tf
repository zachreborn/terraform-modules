terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

resource "aws_organizations_organizational_unit" "this" {
  name      = var.name
  parent_id = var.parent_id
  tags      = var.tags
  lifecycle {
    create_before_destroy = true
  }
}
