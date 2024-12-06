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
resource "aws_apigatewayv2_api" "api" {
  #Required
  name                       = var.name
  protocol_type              = var.protocol_type
  route_selection_expression = "$request.method $request.path"

  #Optional
  api_key_selection_expression = var.api_key_selection_expression
  cors_configuration {
    allow_credentials = lookup(var.cors_configuration, "allow_credentials", null)
    allow_headers     = lookup(var.cors_configuration, "allow_headers", null)
    allow_methods     = lookup(var.cors_configuration, "allow_methods", null)
    allow_origins     = lookup(var.cors_configuration, "allow_origins", null)
    expose_headers    = lookup(var.cors_configuration, "expose_headers", null)
    max_age           = lookup(var.cors_configuration, "max_age", null)
  }
  credentials_arn              = var.credentials_arn
  description                  = var.description
  disable_execute_api_endpoint = var.disable_execute_api_endpoint
  fail_on_warnings             = var.fail_on_warnings
  tags                         = var.tags
  target                       = var.target
  version                      = var.api_gateway_version
  body                         = var.body

  lifecycle {
    ignore_changes = [body]
  }
}
