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

###########################
# Module Configuration
###########################

resource "aws_transfer_server" "this" {
  certificate = var.certificate
  domain = var.domain
  protocols = var.protocols
  endpoint_details {
    address_allocation_ids = var.address_allocation_ids
    security_group_ids = var.security_group_ids
    subnet_ids = var.subnet_ids
    vpc_endpoint_id = var.vpc_endpoint_id
    vpc_id = var.vpc_id
  }
  tags = var.tags
}
