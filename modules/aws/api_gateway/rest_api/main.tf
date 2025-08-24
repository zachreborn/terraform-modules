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
  resource_id = aws_api_gateway_resource.this[each.value.resource].id
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

  http_method         = aws_api_gateway_method.this[each.value.method].http_method
  rest_api_id         = aws_api_gateway_rest_api.this.id
  resource_id         = aws_api_gateway_resource.this[each.value.resource].id
  response_models     = each.value.response_models
  response_parameters = each.value.response_parameters
  status_code         = each.value.status_code
}

resource "aws_api_gateway_integration" "this" {
  for_each = var.integrations != null ? var.integrations : {}

  cache_key_parameters    = each.value.cache_key_parameters
  cache_namespace         = each.value.cache_namespace
  connection_type         = each.value.connection_type
  connection_id           = each.value.connection_type == "VPC_LINK" && each.value.vpc_link_key != null ? aws_api_gateway_vpc_link.this[each.value.vpc_link_key].id : each.value.connection_id
  content_handling        = each.value.content_handling
  credentials             = each.value.credentials
  http_method             = aws_api_gateway_method.this[each.value.method].http_method
  integration_http_method = each.value.type == "MOCK" ? null : each.value.integration_http_method
  passthrough_behavior    = each.value.passthrough_behavior
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.this[each.value.resource].id
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

  name        = each.key
  description = each.value.description
  target_arns = each.value.target_arns
  tags        = var.tags
}

############################################
# S3 Bucket for mTLS Truststore
############################################

resource "aws_s3_bucket" "mtls_truststore" {
  count = var.enable_mtls && var.domain_name != null ? 1 : 0
  #bucket_prefix = "mtls-truststore-"
  bucket = var.bucket_name

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "mtls_truststore" {
  count  = var.enable_mtls && var.domain_name != null ? 1 : 0
  bucket = aws_s3_bucket.mtls_truststore[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mtls_truststore" {
  count  = var.enable_mtls && var.domain_name != null ? 1 : 0
  bucket = aws_s3_bucket.mtls_truststore[0].id

  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Upload truststore.pem file to S3 bucket
resource "aws_s3_object" "truststore_pem" {
  count  = var.enable_mtls && var.domain_name != null ? 1 : 0
  bucket = aws_s3_bucket.mtls_truststore[0].id
  key    = "truststore/truststore.pem"
  source = "${path.root}/truststore/truststore.pem"
  etag   = filemd5("${path.root}/truststore/truststore.pem")

  tags = var.tags

  depends_on = [
    aws_s3_bucket.mtls_truststore
  ]
}

############################################
# ACM Certificate for Custom Domain
############################################

resource "aws_acm_certificate" "domain" {
  count             = var.enable_mtls && var.domain_name != null ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = merge(var.tags, {
    Name = "API Gateway Domain Certificate"
  })

  lifecycle {
    create_before_destroy = true
  }
}

############################################
# API Gateway Custom Domain Name and mTLS
############################################

resource "aws_api_gateway_domain_name" "this" {
  count = var.enable_mtls && var.domain_name != null ? 1 : 0

  domain_name              = var.domain_name
  regional_certificate_arn = var.certificate_arn != null ? var.certificate_arn : aws_acm_certificate.domain[0].arn
  security_policy          = var.security_policy

  endpoint_configuration {
    types = var.endpoint_configuration_types
  }

  dynamic "mutual_tls_authentication" {
    for_each = var.enable_mtls && var.domain_name != null ? [1] : []
    content {
      truststore_uri     = var.mtls_config != null ? var.mtls_config.truststore_uri : "s3://${aws_s3_bucket.mtls_truststore[0].id}/truststore/truststore.pem"
      truststore_version = var.mtls_config != null ? var.mtls_config.truststore_version : aws_s3_object.truststore_pem[0].version_id
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

resource "aws_api_gateway_base_path_mapping" "this" {
  count = var.enable_mtls && var.domain_name != null ? 1 : 0

  api_id      = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  domain_name = aws_api_gateway_domain_name.this[0].domain_name
}

############################################
# API Gateway Deployment and Stage
############################################

resource "aws_api_gateway_deployment" "this" {
  depends_on = [
    aws_api_gateway_method.this,
    aws_api_gateway_integration.this
  ]

  rest_api_id = aws_api_gateway_rest_api.this.id

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id
  stage_name    = var.stage_name

  tags = var.tags
}
