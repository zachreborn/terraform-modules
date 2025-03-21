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
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#############################
# API Gateway
#############################
resource "aws_api_gateway_rest_api" "this" {
  api_key_source               = var.api_key_source
  binary_media_types           = var.binary_media_types
  body                         = var.body
  description                  = var.description
  disable_execute_api_endpoint = var.disable_execute_api_endpoint
  minimum_compression_size     = var.minimum_compression_size
  name                         = var.name
  fail_on_warnings             = var.fail_on_warnings
  parameters                   = var.parameters
  policy                       = var.policy
  put_rest_api_mode            = var.put_rest_api_mode
  tags                         = var.tags

  dynamic "endpoint_configuration" {
    for_each = var.endpoint_configuration != null ? [var.endpoint_configuration] : []
    content {
      types = [for type in var.endpoint_configuration.types : type]
    }
  }
}
