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
resource "aws_apigatewayv2_api" "this" {
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
  version                      = var.api_version

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
}

############################################
# Authorizers
############################################

resource "aws_apigatewayv2_authorizer" "this" {
  for_each = var.authorizers != null ? var.authorizers : {}

  api_id                            = aws_apigatewayv2_api.this.id
  authorizer_type                   = each.value.authorizer_type
  identity_sources                  = each.value.identity_sources
  name                              = each.key
  authorizer_uri                    = each.value.authorizer_uri
  authorizer_credentials_arn        = each.value.authorizer_credentials_arn
  authorizer_payload_format_version = each.value.authorizer_payload_format_version
  enable_simple_responses           = each.value.enable_simple_responses

  dynamic "jwt_configuration" {
    for_each = var.jwt_configuration != null ? [var.jwt_configuration] : []
    content {
      audience = each.value.audience
      issuer   = each.value.issuer
    }
  }
}

############################################
# Custom Domain Names
############################################
resource "aws_apigatewayv2_domain_name" "this" {
  for_each = var.domain_names != null ? var.domain_names : {}

  domain_name = each.key
  tags        = var.tags

  domain_name_configuration {
    certificate_arn                        = each.value.certificate_arn
    endpoint_type                          = each.value.endpoint_type
    ownership_verification_certificate_arn = each.value.ownership_verification_certificate_arn
    security_policy                        = each.value.security_policy
  }

  dynamic "mutual_tls_authentication" {
    for_each = var.mutual_tls_authentication != null ? [var.mutual_tls_authentication] : []
    content {
      truststore_uri     = mutual_tls_authentication.value.truststore_uri
      truststore_version = mutual_tls_authentication.value.truststore_version
    }
  }
}

############################################
# Integrations
############################################
resource "aws_apigatewayv2_integration" "this" {
  for_each = var.integrations != null ? var.integrations : {}

  api_id                        = aws_apigatewayv2_api.this.id
  connection_id                 = each.value.connection_id
  connection_type               = each.value.connection_type
  content_handling_strategy     = each.value.content_handling_strategy
  credentials_arn               = each.value.credentials_arn
  description                   = each.value.description
  integration_method            = each.value.integration_method
  integration_subtype           = each.value.integration_subtype
  integration_type              = each.value.integration_type
  integration_uri               = each.value.integration_uri
  passthrough_behavior          = each.value.passthrough_behavior
  payload_format_version        = each.value.payload_format_version
  request_parameters            = each.value.request_parameters
  request_templates             = each.value.request_templates
  template_selection_expression = each.value.template_selection_expression
  timeout_milliseconds          = each.value.timeout_milliseconds
  dynamic "response_parameters" {
    for_each = each.value.response_parameters != null ? each.value.response_parameters : {}
    content {
      mappings    = response_parameters.value.mappings
      status_code = response_parameters.value.status_code
    }
  }

  dynamic "tls_config" {
    for_each = each.value.tls_config != null ? [each.value.tls_config] : []
    content {
      server_name_to_verify = tls_config.value.server_name_to_verify
    }
  }
}

############################################
# Integration Responses
############################################

resource "aws_apigatewayv2_integration_response" "this" {
  for_each = var.integration_responses != null ? var.integration_responses : {}

  api_id                        = aws_apigatewayv2_api.this.id
  integration_id                = each.value.integration_id
  integration_response_key      = each.value.integration_response_key
  content_handling_strategy     = each.value.content_handling_strategy
  response_templates            = each.value.response_templates
  template_selection_expression = each.value.template_selection_expression
}

############################################
# Models
############################################

resource "aws_apigatewayv2_model" "this" {
  for_each = var.models != null ? var.models : {}

  api_id       = aws_apigatewayv2_api.this.id
  content_type = each.value.content_type
  description  = each.value.description
  name         = each.key
  schema       = each.value.schema
}


############################################
# Routes
############################################

resource "aws_apigatewayv2_route" "this" {
  for_each = var.routes != null ? var.routes : {}

  api_id                              = aws_apigatewayv2_api.this.id
  api_key_required                    = each.value.api_key_required
  authorization_scopes                = each.value.authorization_scopes
  authorization_type                  = each.value.authorization_type
  authorizer_id                       = each.value.authorizer_id
  model_selection_expression          = each.value.model_selection_expression
  operation_name                      = each.value.operation_name
  request_models                      = each.value.request_models
  route_key                           = each.value.route_key
  route_response_selection_expression = each.value.route_response_selection_expression
  target                              = each.value.target

  dynamic "request_parameter" {
    for_each = each.value.request_parameter != null ? each.value.request_parameter : {}
    content {
      request_parameter_key = request_parameter.value.request_parameter_key
      required              = request_parameter.value.required
    }
  }
}

############################################
# Route Responses
############################################

resource "aws_apigatewayv2_route_response" "this" {
  for_each = var.route_responses != null ? var.route_responses : {}

  api_id                     = aws_apigatewayv2_api.this.id
  route_id                   = each.value.route_id
  route_response_key         = each.value.route_response_key
  response_models            = each.value.response_models
  model_selection_expression = each.value.model_selection_expression
}


############################################
# Stages
############################################
resource "aws_apigatewayv2_stage" "this" {
  for_each = var.stages != null ? var.stages : {}

  api_id      = aws_apigatewayv2_api.this.id
  auto_deploy = each.value.auto_deploy
  name        = each.key
  tags        = var.tags

  dynamic "access_log_settings" {
    for_each = each.value.access_log_settings != null ? [each.value.access_log_settings] : []
    content {
      destination_arn = access_log_settings.value.destination_arn
      format          = access_log_settings.value.format
    }
  }

  dynamic "default_route_settings" {
    for_each = each.value.default_route_settings != null ? [each.value.default_route_settings] : []
    content {
      data_trace_enabled       = default_route_settings.value.data_trace_enabled
      detailed_metrics_enabled = default_route_settings.value.detailed_metrics_enabled
      logging_level            = default_route_settings.value.logging_level
      throttling_burst_limit   = default_route_settings.value.throttling_burst_limit
      throttling_rate_limit    = default_route_settings.value.throttling_rate_limit
    }
  }

  dynamic "route_settings" {
    for_each = each.value.route_settings != null ? each.value.route_settings : {}
    content {
      route_key                = route_settings.key
      data_trace_enabled       = route_settings.value.data_trace_enabled
      detailed_metrics_enabled = route_settings.value.detailed_metrics_enabled
      logging_level            = route_settings.value.logging_level
      throttling_burst_limit   = route_settings.value.throttling_burst_limit
      throttling_rate_limit    = route_settings.value.throttling_rate_limit
    }
  }
}


############################################
# VPC Links
############################################
resource "aws_apigatewayv2_vpc_link" "this" {
  for_each = var.vpc_links != null ? var.vpc_links : {}

  name               = each.key
  security_group_ids = each.value.security_group_ids
  subnet_ids         = each.value.subnet_ids
  tags               = var.tags
}
