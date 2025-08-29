terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

resource "aws_db_parameter_group" "group" {
  description = var.description
  family      = var.family
  name        = var.name
  tags        = var.tags
}
