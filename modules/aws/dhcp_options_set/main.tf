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
# VPC DHCP Options
###########################

resource "aws_vpc_dhcp_options" "this" {
  domain_name         = var.domain_name
  domain_name_servers = var.domain_name_servers
  ntp_servers         = var.ntp_servers
  tags                = var.tags
}

resource "aws_vpc_dhcp_options_association" "this" {
  dhcp_options_id = aws_vpc_dhcp_options.this.id
  vpc_id          = var.vpc_id
}
