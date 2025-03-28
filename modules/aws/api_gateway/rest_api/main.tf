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

############################################
# API Gateway Resources
############################################

resource "aws_api_gateway_resource" "this" {
  for_each = var.resources != null ? var.resources : {}
  # Points to the api gateway.
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  # Allows for different paths for different resources. 
  path_part = each.value.path_part
}

############################################
# API Gateway Methods
############################################

resource "aws_api_gateway_method" "this" {
  for_each = var.methods != null ? var.methods : {}
  # Points methods to the api gateway
  resource_id = aws_api_gateway_resource.this.id
  rest_api_id = aws_api_gateway_rest_api.this.id
  # Method details
  api_key_required     = each.value.api_key_required
  authorization        = each.value.authorization
  authorizer_id        = each.value.authorizer_id
  authorization_scopes = each.value.authorization_scopes
  http_method          = each.value.http_method
  operation_name       = each.value.operation_name
  request_models       = each.value.request_models
  request_parameters   = each.value.request_parameters
  request_validator_id = each.value.request_validator_id
}

resource "aws_api_gateway_method_response" "this" {
  for_each = var.method_responses != null ? var.method_responses : {}

  http_method         = aws_api_gateway_method.this.http_method
  rest_api_id         = aws_api_gateway_rest_api.this.id
  resource_id         = aws_api_gateway_resource.this.id
  response_models     = each.value.response_models
  response_parameters = each.value.response_parameters
  status_code         = each.value.status_code
}

resource "aws_api_gateway_integration" "this" {
  for_each = var.integrations != null ? var.integrations : {}

  cache_key_parameters    = each.value.cache_key_parameters
  cache_namespace         = each.value.cache_namespace
  connection_type         = each.value.connection_type
  connection_id           = each.value.connection_id
  content_handling        = each.value.content_handling
  credentials             = each.value.credentials
  http_method             = aws_api_gateway_method.this.http_method
  integration_http_method = each.value.integration_http_method
  passthrough_behavior    = each.value.passthrough_behavior
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.this.id
  request_parameters      = each.value.request_parameters
  request_templates       = each.value.request_templates
  timeout_milliseconds    = each.value.timeout_milliseconds
  type                    = each.value.type
  uri                     = each.value.uri
}

############################################
# API Gateway VPC Link
############################################

resource "aws_api_gateway_vpc_link" "this" {
  for_each = var.vpc_links != null ? var.vpc_links : {}

  name        = each.value.name
  description = each.value.description
  target_arns = each.value.target_arns
  tags        = var.tags
}
