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

##############
# Create logging IAM role
##############

##############
# Create CloudWatch log group
##############

##############
# Create the AWS transfer family server
##############

resource "aws_transfer_server" "this" {
  certificate                      = var.certificate
  directory_id                     = var.directory_id
  domain                           = var.storage_location
  endpoint_type                    = var.endpoint_type
  function                         = var.function
  host_key                         = var.host_key
  identity_provider_type           = var.identity_provider_type
  invocation_role                  = var.invocation_role
  logging_role                     = var.logging_role
  pre_authentication_login_banner  = var.pre_authentication_login_banner
  post_authentication_login_banner = var.post_authentication_login_banner
  protocols                        = var.protocols
  security_policy_name             = var.security_policy_name
  url                              = var.url
  tags                             = var.tags

  dynamic "endpoint_details" {
    for_each = var.endpoint_type == "VPC" ? [1] : []
    content {
      address_allocation_ids = var.address_allocation_ids
      security_group_ids     = var.security_group_ids
      subnet_ids             = var.subnet_ids
      vpc_endpoint_id        = var.vpc_endpoint_id
      vpc_id                 = var.vpc_id
    }
  }
  protocol_details {
    as2_transports              = var.as2_transports
    passive_ip                  = var.passive_ip
    set_stat_option             = var.set_stat_option
    tls_session_resumption_mode = var.tls_session_resumption_mode
  }
}


##############
# Create the transfer family server access
##############




##############
# Create the transfer family server workflow
##############