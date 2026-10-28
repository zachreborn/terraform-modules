terraform {
  # Optional object defaults require Terraform 1.3 (also covers preconditions).
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # Custom-domain routing_mode was introduced in AWS provider 6.29.0.
      version = ">= 6.29.0"
    }
  }
}

###########################
# Normalized Configuration
###########################
locals {
  # Filter null entries only after their owning variable reports the actionable error.

  authorizers           = { for k, v in coalesce(var.authorizers, {}) : k => v if v != null }
  domain_names          = { for k, v in coalesce(var.domain_names, {}) : k => v if v != null }
  integrations          = { for k, v in coalesce(var.integrations, {}) : k => v if v != null }
  integration_responses = { for k, v in coalesce(var.integration_responses, {}) : k => v if v != null }
  models                = { for k, v in coalesce(var.models, {}) : k => v if v != null }
  routes                = { for k, v in coalesce(var.routes, {}) : k => v if v != null }
  route_responses       = { for k, v in coalesce(var.route_responses, {}) : k => v if v != null }
  stages                = { for k, v in coalesce(var.stages, {}) : k => v if v != null }
  vpc_links             = { for k, v in coalesce(var.vpc_links, {}) : k => v if v != null }

  cors_configured = var.cors_configuration == null ? false : (
    var.cors_configuration.allow_credentials ||
    var.cors_configuration.max_age != 0 ||
    anytrue([for items in [var.cors_configuration.allow_headers, var.cors_configuration.allow_methods, var.cors_configuration.allow_origins, var.cors_configuration.expose_headers] : length(coalesce(items, [])) > 0])
  )
  global_jwt_configured = var.jwt_configuration == null ? false : (
    length(coalesce(var.jwt_configuration.audience, [])) > 0 || try(length(trimspace(var.jwt_configuration.issuer)) > 0, false)
  )
  effective_jwt = {
    for k, v in local.authorizers : k => (v.jwt_configuration != null ? v.jwt_configuration : (local.global_jwt_configured ? var.jwt_configuration : null))
  }
  effective_mtls = {
    for k, v in local.domain_names : k => (v.mutual_tls_authentication != null ? v.mutual_tls_authentication : var.mutual_tls_authentication)
  }
}

###########################
# API Gateway
###########################
resource "aws_apigatewayv2_api" "this" {
  region                       = var.region
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
  target                       = var.target
  ip_address_type              = var.ip_address_type
  version                      = var.api_version
  tags                         = merge({ Name = var.name }, var.tags)
  dynamic "cors_configuration" {
    for_each = local.cors_configured ? [var.cors_configuration] : []
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
    precondition {
      condition     = !local.cors_configured || var.protocol_type == "HTTP"
      error_message = "Meaningful CORS is supported only on HTTP APIs."
    }
    precondition {
      condition     = var.body == null || var.protocol_type == "HTTP"
      error_message = "OpenAPI body is supported only on HTTP APIs."
    }
    precondition {
      condition     = var.body == null || (length(local.integrations) == 0 && length(local.routes) == 0 && !local.cors_configured && var.api_version == null)
      error_message = "OpenAPI body cannot overlap explicit integrations/routes, meaningful CORS or api_version."
    }
    precondition {
      condition     = var.target == null || (length(local.integrations) == 0 && length(local.routes) == 0 && length(local.stages) == 0)
      error_message = "Quick-create target cannot overlap explicit integrations, routes or stages."
    }
    precondition {
      condition     = var.protocol_type == "HTTP" || (var.target == null && var.route_key == null && var.credentials_arn == null && var.fail_on_warnings != true)
      error_message = "Quick-create settings and fail_on_warnings are HTTP-only."
    }
    precondition {
      condition     = var.body == null || (var.target == null && var.route_key == null && var.credentials_arn == null)
      error_message = "OpenAPI body cannot overlap quick-create configuration."
    }
  }
}

###########################
# Authorizers
###########################
resource "aws_apigatewayv2_authorizer" "this" {
  for_each                          = local.authorizers
  region                            = var.region
  api_id                            = aws_apigatewayv2_api.this.id
  name                              = each.key
  authorizer_type                   = each.value.authorizer_type
  authorizer_uri                    = each.value.authorizer_uri
  identity_sources                  = each.value.identity_sources
  authorizer_credentials_arn        = each.value.authorizer_credentials_arn
  authorizer_payload_format_version = each.value.authorizer_payload_format_version
  enable_simple_responses           = each.value.enable_simple_responses
  authorizer_result_ttl_in_seconds  = each.value.authorizer_result_ttl_in_seconds != null ? each.value.authorizer_result_ttl_in_seconds : each.value.authorizer_result_ttl
  dynamic "jwt_configuration" {
    for_each = each.value.authorizer_type == "JWT" && local.effective_jwt[each.key] != null ? [local.effective_jwt[each.key]] : []
    content {
      audience = jwt_configuration.value.audience
      issuer   = jwt_configuration.value.issuer
    }
  }
  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      delete = timeouts.value.delete
    }
  }
  lifecycle {
    precondition {
      condition     = var.protocol_type != "HTTP" || each.value.authorizer_type != "REQUEST" || each.value.authorizer_payload_format_version != null
      error_message = "HTTP REQUEST authorizers require authorizer_payload_format_version."
    }
    precondition {
      condition     = each.value.authorizer_type != "JWT" || try(length(local.effective_jwt[each.key].audience) > 0 && length(trimspace(local.effective_jwt[each.key].issuer)) > 0, false)
      error_message = "JWT authorizers require a nonempty audience and issuer, nested or global."
    }
    precondition {
      condition     = each.value.jwt_configuration == null || !local.global_jwt_configured || each.value.jwt_configuration == var.jwt_configuration
      error_message = "Nested and global JWT configurations must agree when both supplied."
    }
    precondition {
      condition     = var.protocol_type != "WEBSOCKET" || (each.value.authorizer_type != "JWT" && each.value.authorizer_payload_format_version == null && each.value.enable_simple_responses == null)
      error_message = "JWT, payload format and simple responses are HTTP-only authorizer settings."
    }
  }
}

###########################
# Custom Domain Names
###########################
resource "aws_apigatewayv2_domain_name" "this" {
  for_each     = local.domain_names
  region       = var.region
  domain_name  = each.key
  routing_mode = each.value.routing_mode
  tags         = merge({ Name = each.key }, var.tags)
  domain_name_configuration {

    certificate_arn                        = each.value.domain_name_configuration.certificate_arn
    endpoint_type                          = each.value.domain_name_configuration.endpoint_type
    security_policy                        = each.value.domain_name_configuration.security_policy
    ownership_verification_certificate_arn = each.value.domain_name_configuration.ownership_verification_certificate_arn
    ip_address_type                        = each.value.domain_name_configuration.ip_address_type
  }
  dynamic "mutual_tls_authentication" {
    for_each = local.effective_mtls[each.key] == null ? [] : [local.effective_mtls[each.key]]
    content {
      truststore_uri     = mutual_tls_authentication.value.truststore_uri
      truststore_version = mutual_tls_authentication.value.truststore_version
    }
  }
  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
    }
  }
  lifecycle {
    precondition {
      condition     = each.value.mutual_tls_authentication == null || var.mutual_tls_authentication == null || each.value.mutual_tls_authentication == var.mutual_tls_authentication
      error_message = "Nested and global mutual TLS configurations must agree."
    }
  }
}

###########################
# Integrations
###########################
resource "aws_apigatewayv2_integration" "this" {
  for_each                      = local.integrations
  region                        = var.region
  api_id                        = aws_apigatewayv2_api.this.id
  connection_type               = coalesce(each.value.connection_type, "INTERNET")
  content_handling_strategy     = each.value.content_handling_strategy
  credentials_arn               = each.value.credentials_arn
  description                   = each.value.description
  integration_method            = each.value.integration_method
  integration_subtype           = each.value.integration_subtype
  integration_type              = each.value.integration_type
  integration_uri               = each.value.integration_uri
  passthrough_behavior          = each.value.passthrough_behavior
  payload_format_version        = coalesce(each.value.payload_format_version, "1.0")
  request_parameters            = each.value.request_parameters
  request_templates             = each.value.request_templates
  template_selection_expression = each.value.template_selection_expression
  timeout_milliseconds          = each.value.timeout_milliseconds
  connection_id                 = each.value.vpc_link_key == null ? each.value.connection_id : try(aws_apigatewayv2_vpc_link.this[each.value.vpc_link_key].id, null)
  dynamic "response_parameters" {
    for_each = { for k, v in each.value.response_parameters : k => v if v != null }
    content {
      mappings    = response_parameters.value.mappings
      status_code = response_parameters.value.status_code
    }
  }
  dynamic "tls_config" {
    for_each = each.value.tls_config == null ? [] : [each.value.tls_config]
    content {
      server_name_to_verify = tls_config.value.server_name_to_verify
    }
  }
  lifecycle {
    precondition {
      condition     = each.value.connection_id == null || each.value.vpc_link_key == null
      error_message = "Specify connection_id or vpc_link_key, not both."
    }
    precondition {
      condition     = each.value.vpc_link_key == null ? true : contains(keys(local.vpc_links), each.value.vpc_link_key)
      error_message = "vpc_link_key must identify an existing VPC-link map key."
    }
    precondition {
      condition     = var.protocol_type != "WEBSOCKET" || try(each.value.timeout_milliseconds == null ? true : each.value.timeout_milliseconds <= 29000, true)
      error_message = "WebSocket integration timeout must not exceed 29000 milliseconds."
    }
    precondition {
      condition     = var.protocol_type != "HTTP" || each.value.content_handling_strategy == null
      error_message = "Integration content handling is WebSocket-only."
    }
    precondition {
      condition     = var.protocol_type != "HTTP" || !try(contains(["AWS", "HTTP", "MOCK"], each.value.integration_type), false)
      error_message = "HTTP APIs support AWS_PROXY or HTTP_PROXY integrations; AWS, HTTP and MOCK require WebSocket."
    }
    precondition {
      condition     = var.protocol_type != "HTTP" || (each.value.passthrough_behavior == null && length(coalesce(each.value.request_templates, {})) == 0)
      error_message = "Integration passthrough_behavior and request_templates are WebSocket-only."
    }
    precondition {
      condition     = var.protocol_type != "WEBSOCKET" || (each.value.connection_id == null && each.value.vpc_link_key == null && each.value.connection_type != "VPC_LINK")
      error_message = "VPC-link connections are supported only for HTTP APIs."
    }
    precondition {
      condition     = var.protocol_type != "WEBSOCKET" || (each.value.integration_subtype == null && length(each.value.response_parameters) == 0 && each.value.tls_config == null && each.value.payload_format_version != "2.0")
      error_message = "Integration subtype, response parameters, TLS and payload 2.0 require HTTP."
    }
  }
}

###########################
# Integration Responses
###########################
resource "aws_apigatewayv2_integration_response" "this" {
  for_each                      = local.integration_responses
  region                        = var.region
  api_id                        = aws_apigatewayv2_api.this.id
  integration_response_key      = each.value.integration_response_key
  content_handling_strategy     = each.value.content_handling_strategy
  response_templates            = each.value.response_templates
  template_selection_expression = each.value.template_selection_expression
  integration_id                = each.value.integration_key == null ? each.value.integration_id : try(aws_apigatewayv2_integration.this[each.value.integration_key].id, null)
  lifecycle {
    precondition {
      condition     = (each.value.integration_id != null) != (each.value.integration_key != null)
      error_message = "Exactly one integration_id or integration_key is required."
    }
    precondition {
      condition     = each.value.integration_key == null ? true : contains(keys(local.integrations), each.value.integration_key)
      error_message = "integration_key must identify an existing integration map key."
    }
    precondition {
      condition     = var.protocol_type == "WEBSOCKET"
      error_message = "Integration response resources are WebSocket-only."
    }
  }
}

###########################
# Models
###########################
resource "aws_apigatewayv2_model" "this" {
  for_each     = local.models
  region       = var.region
  api_id       = aws_apigatewayv2_api.this.id
  name         = each.key
  content_type = each.value.content_type
  description  = each.value.description
  schema       = each.value.schema
  lifecycle {
    precondition {
      condition     = var.protocol_type == "WEBSOCKET"
      error_message = "Model resources are WebSocket-only."
    }
  }
}

###########################
# Routes
###########################
resource "aws_apigatewayv2_route" "this" {
  for_each                            = local.routes
  region                              = var.region
  api_id                              = aws_apigatewayv2_api.this.id
  api_key_required                    = each.value.api_key_required
  authorization_scopes                = each.value.authorization_scopes
  authorization_type                  = each.value.authorization_type
  model_selection_expression          = each.value.model_selection_expression
  operation_name                      = each.value.operation_name
  request_models                      = each.value.request_models
  route_key                           = each.value.route_key
  route_response_selection_expression = each.value.route_response_selection_expression
  target                              = each.value.integration_key == null ? each.value.target : try("integrations/${aws_apigatewayv2_integration.this[each.value.integration_key].id}", null)
  authorizer_id                       = each.value.authorizer_key == null ? each.value.authorizer_id : try(aws_apigatewayv2_authorizer.this[each.value.authorizer_key].id, null)
  dynamic "request_parameter" {
    for_each = { for k, v in merge({ for k, v in coalesce(each.value.request_parameters, {}) : k => { request_parameter_key = k, required = try(tobool(v), false) } }, each.value.request_parameter) : k => v if v != null }
    content {
      request_parameter_key = request_parameter.value.request_parameter_key
      required              = request_parameter.value.required
    }
  }
  lifecycle {
    precondition {
      condition     = each.value.target == null || each.value.integration_key == null
      error_message = "Specify target or integration_key, not both."
    }
    precondition {
      condition     = each.value.integration_key == null ? true : contains(keys(local.integrations), each.value.integration_key)
      error_message = "integration_key must identify an existing integration map key."
    }
    precondition {
      condition     = each.value.authorizer_id == null || each.value.authorizer_key == null
      error_message = "Specify authorizer_id or authorizer_key, not both."
    }
    precondition {
      condition     = each.value.authorizer_key == null ? true : contains(keys(local.authorizers), each.value.authorizer_key)
      error_message = "authorizer_key must identify an existing authorizer map key."
    }
    precondition {
      condition     = each.value.target == null ? true : can(regex("^integrations/[^/]+$", each.value.target))
      error_message = "Literal route targets must use integrations/<id>."
    }
    precondition {
      condition     = var.protocol_type != "HTTP" || (each.value.api_key_required != true && each.value.model_selection_expression == null && length(coalesce(each.value.request_models, {})) == 0 && length(each.value.request_parameter) == 0 && length(coalesce(each.value.request_parameters, {})) == 0 && each.value.route_response_selection_expression == null)
      error_message = "Route API keys, models, parameters and response selection are WebSocket-only."
    }
    precondition {
      condition     = var.protocol_type != "WEBSOCKET" || (each.value.authorization_type != "JWT" && length(coalesce(each.value.authorization_scopes, [])) == 0)
      error_message = "Route JWT authorization and scopes are HTTP-only."
    }
  }
}

###########################
# Route Responses
###########################
resource "aws_apigatewayv2_route_response" "this" {
  for_each                   = local.route_responses
  region                     = var.region
  api_id                     = aws_apigatewayv2_api.this.id
  route_response_key         = each.value.route_response_key
  response_models            = each.value.response_models
  model_selection_expression = each.value.model_selection_expression
  route_id                   = each.value.route_key == null ? each.value.route_id : try(aws_apigatewayv2_route.this[each.value.route_key].id, null)
  lifecycle {
    precondition {
      condition     = (each.value.route_id != null) != (each.value.route_key != null)
      error_message = "Exactly one route_id or logical route_key is required."
    }
    precondition {
      condition     = each.value.route_key == null ? true : contains(keys(local.routes), each.value.route_key)
      error_message = "route_key must identify a logical route map key, not an HTTP route string."
    }
    precondition {
      condition     = var.protocol_type == "WEBSOCKET"
      error_message = "Route response resources are WebSocket-only."
    }
  }
}

###########################
# Stages
###########################
resource "aws_apigatewayv2_stage" "this" {
  for_each              = local.stages
  region                = var.region
  api_id                = aws_apigatewayv2_api.this.id
  name                  = each.key
  tags                  = merge({ Name = each.key }, var.tags, coalesce(each.value.tags, {}))
  auto_deploy           = coalesce(each.value.auto_deploy, false)
  description           = each.value.description
  client_certificate_id = each.value.client_certificate_id
  deployment_id         = each.value.deployment_id
  stage_variables       = each.value.stage_variables
  dynamic "access_log_settings" {
    for_each = each.value.access_log_settings == null ? [] : [each.value.access_log_settings]
    content {
      destination_arn = access_log_settings.value.destination_arn
      format          = access_log_settings.value.format
    }
  }
  dynamic "default_route_settings" {
    for_each = each.value.default_route_settings == null ? [] : [each.value.default_route_settings]
    content {
      data_trace_enabled       = var.protocol_type == "HTTP" ? null : default_route_settings.value.data_trace_enabled
      detailed_metrics_enabled = default_route_settings.value.detailed_metrics_enabled
      logging_level            = var.protocol_type == "HTTP" ? null : default_route_settings.value.logging_level
      throttling_burst_limit   = default_route_settings.value.throttling_burst_limit
      throttling_rate_limit    = default_route_settings.value.throttling_rate_limit
    }
  }
  dynamic "route_settings" {
    for_each = { for k, v in each.value.route_settings : k => v if v != null }
    content {
      route_key                = route_settings.key
      data_trace_enabled       = var.protocol_type == "HTTP" ? null : route_settings.value.data_trace_enabled
      detailed_metrics_enabled = route_settings.value.detailed_metrics_enabled
      logging_level            = var.protocol_type == "HTTP" ? null : route_settings.value.logging_level
      throttling_burst_limit   = route_settings.value.throttling_burst_limit
      throttling_rate_limit    = route_settings.value.throttling_rate_limit
    }
  }
  lifecycle {
    precondition {
      condition     = var.protocol_type != "HTTP" || each.value.client_certificate_id == null
      error_message = "Stage client certificates are WebSocket-only."
    }
    precondition {
      condition     = var.protocol_type != "HTTP" || alltrue([for s in concat(each.value.default_route_settings == null ? [] : [each.value.default_route_settings], values(each.value.route_settings)) : s == null ? true : s.data_trace_enabled != true && s.logging_level == null])
      error_message = "HTTP stages do not support data tracing or logging_level; use access_log_settings instead."
    }
  }
}

###########################
# VPC Links
###########################
resource "aws_apigatewayv2_vpc_link" "this" {
  for_each           = local.vpc_links
  region             = var.region
  name               = each.key
  security_group_ids = each.value.security_group_ids
  subnet_ids         = each.value.subnet_ids
  tags               = merge({ Name = each.key }, var.tags, coalesce(each.value.tags, {}))
}
