###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Data Sources
###########################
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

###########################
# Locals
###########################
locals {
  # Deployment hash for triggering redeployments when configuration changes
  # This ensures the API Gateway is redeployed when any of these configurations change
  deployment_components = {
    resources             = var.resources
    methods               = var.methods
    integrations          = var.integrations
    integration_responses = var.integration_responses
    models                = var.models
    request_validators    = var.request_validators
    authorizers           = var.authorizers
    gateway_responses     = var.gateway_responses
    stage_variables       = var.stage_variables
    stage_description     = var.stage_description
    stage_cache_enabled   = var.cache_cluster_enabled
    stage_xray_enabled    = var.xray_tracing_enabled
    stage_method_settings = var.method_settings
    stage_access_log      = var.access_log_settings
    stage_throttle        = var.stage_throttle_settings
  }
  deployment_hash = sha1(jsonencode(local.deployment_components))
}

###########################
# Primary Resource: API Gateway REST API
###########################
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
      types            = endpoint_configuration.value.types
      vpc_endpoint_ids = endpoint_configuration.value.vpc_endpoint_ids
    }
  }
}

############################################
# API Gateway Resources
############################################
resource "aws_api_gateway_resource" "this" {
  for_each = var.resources

  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = each.value.path_part
}

############################################
# API Gateway Models
############################################
resource "aws_api_gateway_model" "this" {
  for_each = var.models

  rest_api_id  = aws_api_gateway_rest_api.this.id
  name         = each.key
  description  = each.value.description
  content_type = each.value.content_type
  schema       = each.value.schema
}

############################################
# API Gateway Request Validators
############################################
resource "aws_api_gateway_request_validator" "this" {
  for_each = var.request_validators

  rest_api_id                 = aws_api_gateway_rest_api.this.id
  name                        = coalesce(each.value.name, each.key)
  validate_request_body       = each.value.validate_request_body
  validate_request_parameters = each.value.validate_request_parameters
}

############################################
# API Gateway Authorizers
############################################
resource "aws_api_gateway_authorizer" "this" {
  for_each = var.authorizers

  rest_api_id                      = aws_api_gateway_rest_api.this.id
  name                             = each.key
  type                             = each.value.type
  authorizer_uri                   = each.value.authorizer_uri
  authorizer_credentials           = each.value.authorizer_credentials
  identity_source                  = each.value.identity_source
  identity_validation_expression   = each.value.identity_validation_expression
  authorizer_result_ttl_in_seconds = each.value.authorizer_result_ttl_in_seconds
  provider_arns                    = each.value.provider_arns
}

############################################
# API Gateway Methods
############################################
resource "aws_api_gateway_method" "this" {
  for_each = var.methods

  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = aws_api_gateway_resource.this[each.value.resource].id
  http_method          = each.value.http_method
  authorization        = each.value.authorization
  authorizer_id        = each.value.authorizer_id != null ? (can(aws_api_gateway_authorizer.this[each.value.authorizer_id]) ? aws_api_gateway_authorizer.this[each.value.authorizer_id].id : each.value.authorizer_id) : null
  authorization_scopes = each.value.authorization_scopes
  api_key_required     = each.value.api_key_required
  operation_name       = each.value.operation_name
  request_models       = each.value.request_models
  request_parameters   = each.value.request_parameters
  request_validator_id = each.value.request_validator_id != null ? (can(aws_api_gateway_request_validator.this[each.value.request_validator_id]) ? aws_api_gateway_request_validator.this[each.value.request_validator_id].id : each.value.request_validator_id) : null
}

############################################
# API Gateway Method Responses
############################################
resource "aws_api_gateway_method_response" "this" {
  for_each = var.method_responses

  rest_api_id         = aws_api_gateway_rest_api.this.id
  resource_id         = aws_api_gateway_resource.this[each.value.resource].id
  http_method         = aws_api_gateway_method.this[each.value.method].http_method
  status_code         = each.value.status_code
  response_models     = each.value.response_models
  response_parameters = each.value.response_parameters
}

############################################
# API Gateway Integrations
############################################
resource "aws_api_gateway_integration" "this" {
  for_each = var.integrations

  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.this[each.value.resource].id
  http_method             = aws_api_gateway_method.this[each.value.method].http_method
  type                    = each.value.type
  uri                     = each.value.uri
  integration_http_method = each.value.type == "MOCK" ? null : each.value.integration_http_method
  credentials             = each.value.credentials
  connection_type         = each.value.connection_type
  connection_id           = each.value.connection_type == "VPC_LINK" && each.value.vpc_link_key != null ? aws_api_gateway_vpc_link.this[each.value.vpc_link_key].id : each.value.connection_id
  request_parameters      = each.value.request_parameters
  request_templates       = each.value.request_templates
  passthrough_behavior    = each.value.passthrough_behavior
  content_handling        = each.value.content_handling
  timeout_milliseconds    = each.value.timeout_milliseconds
  cache_key_parameters    = each.value.cache_key_parameters
  cache_namespace         = each.value.cache_namespace
}

############################################
# API Gateway Integration Responses
############################################
resource "aws_api_gateway_integration_response" "this" {
  for_each = var.integration_responses

  rest_api_id         = aws_api_gateway_rest_api.this.id
  resource_id         = aws_api_gateway_resource.this[each.value.resource].id
  http_method         = aws_api_gateway_method.this[each.value.method].http_method
  status_code         = each.value.status_code
  selection_pattern   = each.value.selection_pattern
  response_parameters = each.value.response_parameters
  response_templates  = each.value.response_templates
  content_handling    = each.value.content_handling

  depends_on = [aws_api_gateway_integration.this]
}

############################################
# API Gateway Gateway Responses
############################################
resource "aws_api_gateway_gateway_response" "this" {
  for_each = var.gateway_responses

  rest_api_id         = aws_api_gateway_rest_api.this.id
  response_type       = each.value.response_type
  status_code         = each.value.status_code
  response_parameters = each.value.response_parameters
  response_templates  = each.value.response_templates
}

############################################
# API Gateway VPC Links
############################################
resource "aws_api_gateway_vpc_link" "this" {
  for_each = var.vpc_links

  name        = each.key
  description = each.value.description
  target_arns = each.value.target_arns
  tags        = var.tags
}

############################################
# API Gateway Deployment
############################################
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  # Trigger redeployment when configuration changes
  triggers = {
    redeployment = local.deployment_hash
  }

  depends_on = [
    aws_api_gateway_method.this,
    aws_api_gateway_integration.this,
    aws_api_gateway_integration_response.this,
    aws_api_gateway_method_response.this,
    aws_api_gateway_model.this,
    aws_api_gateway_request_validator.this,
    aws_api_gateway_authorizer.this,
    aws_api_gateway_gateway_response.this
  ]
}

############################################
# API Gateway Stage
############################################
resource "aws_api_gateway_stage" "this" {
  rest_api_id           = aws_api_gateway_rest_api.this.id
  deployment_id         = aws_api_gateway_deployment.this.id
  stage_name            = var.stage_name
  description           = var.stage_description
  cache_cluster_enabled = var.cache_cluster_enabled
  cache_cluster_size    = var.cache_cluster_enabled ? var.cache_cluster_size : null
  client_certificate_id = var.client_certificate_id
  documentation_version = var.documentation_version
  variables             = var.stage_variables
  xray_tracing_enabled  = var.xray_tracing_enabled
  tags                  = var.tags

  # Access logging configuration
  dynamic "access_log_settings" {
    for_each = var.access_log_settings != null ? [var.access_log_settings] : []
    content {
      destination_arn = access_log_settings.value.destination_arn
      format          = access_log_settings.value.format
    }
  }
}

############################################
# API Gateway Method Settings
############################################
resource "aws_api_gateway_method_settings" "this" {
  for_each = var.method_settings

  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = each.value.method_path

  settings {
    metrics_enabled                            = each.value.metrics_enabled
    logging_level                              = each.value.logging_level
    data_trace_enabled                         = each.value.data_trace_enabled
    throttling_burst_limit                     = each.value.throttling_burst_limit
    throttling_rate_limit                      = each.value.throttling_rate_limit
    caching_enabled                            = each.value.caching_enabled
    cache_ttl_in_seconds                       = each.value.cache_ttl_in_seconds
    cache_data_encrypted                       = each.value.cache_data_encrypted
    require_authorization_for_cache_control    = each.value.require_authorization_for_cache_control
    unauthorized_cache_control_header_strategy = each.value.unauthorized_cache_control_header_strategy
  }
}

############################################
# API Gateway Custom Domain Name
# Note: ACM certificates must be created separately using the acm_certificate module
# to avoid circular dependencies between API Gateway and certificate validation
############################################
resource "aws_api_gateway_domain_name" "this" {
  count = var.domain_name != null ? 1 : 0

  domain_name              = var.domain_name
  regional_certificate_arn = var.certificate_arn
  security_policy          = var.security_policy

  endpoint_configuration {
    types = var.endpoint_configuration_types
  }

  # mTLS configuration - S3 bucket and truststore must be created separately
  dynamic "mutual_tls_authentication" {
    for_each = var.enable_mtls && var.mtls_config != null ? [var.mtls_config] : []
    content {
      truststore_uri     = mutual_tls_authentication.value.truststore_uri
      truststore_version = mutual_tls_authentication.value.truststore_version
    }
  }

  tags = var.tags
}

############################################
# API Gateway Base Path Mapping
############################################
resource "aws_api_gateway_base_path_mapping" "this" {
  count = var.domain_name != null ? 1 : 0

  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this[0].domain_name
  base_path   = var.base_path
}

############################################
# API Gateway Usage Plans
############################################
resource "aws_api_gateway_usage_plan" "this" {
  for_each = var.usage_plans

  name        = each.value.name
  description = each.value.description
  tags        = var.tags

  dynamic "api_stages" {
    for_each = each.value.api_stages
    content {
      api_id = aws_api_gateway_rest_api.this.id
      stage  = api_stages.value.stage_name
    }
  }

  dynamic "quota_settings" {
    for_each = each.value.quota_settings != null ? [each.value.quota_settings] : []
    content {
      limit  = quota_settings.value.limit
      offset = quota_settings.value.offset
      period = quota_settings.value.period
    }
  }

  dynamic "throttle_settings" {
    for_each = each.value.throttle_settings != null ? [each.value.throttle_settings] : []
    content {
      burst_limit = throttle_settings.value.burst_limit
      rate_limit  = throttle_settings.value.rate_limit
    }
  }
}

############################################
# API Gateway API Keys
############################################
resource "aws_api_gateway_api_key" "this" {
  for_each = var.api_keys

  name        = each.value.name
  description = each.value.description
  enabled     = each.value.enabled
  value       = each.value.value
  tags        = var.tags
}

############################################
# API Gateway Usage Plan Keys (Associations)
############################################
resource "aws_api_gateway_usage_plan_key" "this" {
  for_each = var.usage_plan_keys

  key_id        = aws_api_gateway_api_key.this[each.value.api_key_key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this[each.value.usage_plan_key].id
}
