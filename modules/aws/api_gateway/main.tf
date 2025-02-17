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
  api_key_selection_expression = var.api_key_selection_expression
  body                         = var.body
  credentials_arn              = var.credentials_arn
  description                  = var.description
  disable_execute_api_endpoint = var.disable_execute_api_endpoint
  fail_on_warnings             = var.fail_on_warnings
  name                         = var.name
  protocol_type                = var.protocol_type
  route_key                    = var.route_key
  route_selection_expression   = var.route_selection_expression
  tags                         = var.tags
  target                       = var.target
  version                      = var.version

  dynamic "cors_configuration" {
    for_each = var.cors_configuration != null ? [var.cors_configuration] : []
    content {
      allow_credentials = cors_configuration.value.allow_credentials
      allow_headers     = cors_configuration.value.allow_headers
      allow_methods     = cors_configuration.value.allow_methods
      allow_origins     = cors_configuration.value.allow_origins
      expose_headers    = cors_configuration.value.expose_headers
      max_age           = cors_configuration.value.max_age
    }
  }

  lifecycle {
    ignore_changes = [body]
  }
}


# Domain Name
resource "aws_apigatewayv2_domain_name" "this" {
  for_each = var.domain_names != null ? var.domain_names : {}

  domain_name = each.key
  tags        = var.tags

  domain_name_configuration {
    certificate_arn                        = each.value.certificate_arn
    endpoint_type                          = each.value.endpoint_type
    hosted_zone_id                         = each.value.hosted_zone_id
    ownership_verification_certificate_arn = each.value.ownership_verification_certificate_arn
    security_policy                        = each.value.security_policy
    target_domain_name                     = each.value.target_domain_name
  }

  dynamic "mutual_tls_authentication" {
    for_each = var.mutual_tls_authentication != null ? [var.mutual_tls_authentication] : []
    content {
      truststore_uri     = mutual_tls_authentication.value.truststore_uri
      truststore_version = mutual_tls_authentication.value.truststore_version
    }
  }
}
