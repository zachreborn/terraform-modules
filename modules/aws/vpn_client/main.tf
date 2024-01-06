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

# TODO - Create a security group resource for the VPN client

# TODO - Create a ACM certificate to apply to the client vpn endpoint

resource "aws_ec2_client_vpn_endpoint" "this" {
  client_cidr_block      = var.client_cidr_block
  description            = var.description
  dns_servers            = var.dns_servers
  security_group_ids     = var.security_group_ids
  self_service_portal    = var.enable_self_service_portal
  server_certificate_arn = aws_acm_certificate.this.arn
  session_timeout_hours  = var.session_timeout_hours
  split_tunnel           = var.enable_split_tunnel
  tags                   = var.tags
  transport_protocol     = var.transport_protocol
  vpc_id                 = var.vpc_id
  vpn_port               = var.vpn_port

  authentication_options {
    active_directory_id            = var.active_directory_id
    root_certificate_chain_arn     = var.root_certificate_chain_arn
    saml_provider_arn              = var.saml_provider_arn
    self_service_saml_provider_arn = var.self_service_saml_provider_arn
    type                           = var.authentication_type
  }

  client_connect_options {
    enabled             = var.enable_client_connect_options
    lambda_function_arn = var.lambda_function_arn
  }

  client_login_banner_options {
    banner_text = var.banner_text
    enabled     = var.enable_client_login_banner_options
  }

  connection_log_options {
    cloudwatch_log_group  = var.cloudwatch_log_group
    cloudwatch_log_stream = var.cloudwatch_log_stream
    enabled               = var.enable_connection_logging
  }
}

resource "aws_ec2_client_vpn_network_association" "this" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = var.subnet_id
}

resource "aws_ec2_client_vpn_route" "this" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  destination_cidr_block = var.destination_cidr_block
  target_vpc_subnet_id   = aws_ec2_client_vpn_network_association.this.subnet_id
}
