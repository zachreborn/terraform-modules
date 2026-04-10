terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

resource "aws_directory_service_directory" "this" {
  alias       = var.alias
  description = var.description
  name        = var.name
  password    = var.password
  size        = var.size
  tags        = var.tags
  type        = var.type

  vpc_settings {
    subnet_ids = var.subnet_ids
    vpc_id     = var.vpc_id
  }
}
