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
data "aws_cloudfront_cache_policy" "this" {
  count = var.managed_cache_policy_name != null ? 1 : 0
  name  = "Managed-${var.managed_cache_policy_name}"
}

###########################
# Locals
###########################

###########################
# Origin Access Control
###########################
resource "aws_cloudfront_origin_access_control" "this" {
  for_each = var.origin_access_controls != null ? var.origin_access_controls : {}

  name                              = each.key
  description                       = each.value.description
  origin_access_control_origin_type = each.value.origin_access_control_origin_type
  signing_behavior                  = each.value.signing_behavior
  signing_protocol                  = each.value.signing_protocol
}

###########################
# ACM Certificate Validation
###########################
# Optional, gated waiter. When var.wait_for_certificate_validation is true the
# module creates this resource so the distribution is created only after the
# certificate reaches ISSUED. It creates no DNS records; the caller still owns
# the validation records in their own DNS zone. This release uses the module's
# default aws provider, which must target us-east-1 (CloudFront ACM region)
# when this is enabled. A dedicated aws.acm provider alias is deferred to the
# next major version.
resource "aws_acm_certificate_validation" "this" {
  count = var.wait_for_certificate_validation ? 1 : 0

  certificate_arn = var.acm_certificate_arn

  timeouts {
    create = var.certificate_validation_timeout
  }
}

###########################
# Module Configuration
###########################

resource "aws_cloudfront_distribution" "this" {
  aliases                         = var.aliases
  comment                         = var.comment
  continuous_deployment_policy_id = var.continuous_deployment_policy_id
  default_root_object             = var.default_root_object
  enabled                         = var.enabled
  http_version                    = var.http_version
  is_ipv6_enabled                 = var.is_ipv6_enabled
  price_class                     = var.price_class
  retain_on_delete                = var.retain_on_delete
  staging                         = var.staging
  tags                            = var.tags
  wait_for_deployment             = var.wait_for_deployment
  web_acl_id                      = var.web_acl_id

  dynamic "custom_error_response" {
    for_each = var.custom_error_responses != null ? var.custom_error_responses : {}
    content {
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
    }
  }

  default_cache_behavior {
    allowed_methods           = var.default_cache_allowed_methods
    cached_methods            = var.default_cache_cached_methods
    cache_policy_id           = var.managed_cache_policy_name != null ? data.aws_cloudfront_cache_policy.this[0].id : var.default_cache_policy_id
    compress                  = var.default_cache_compress
    field_level_encryption_id = var.default_cache_field_level_encryption_id
    # lambda_function_association block
    # function_association block
    origin_request_policy_id   = var.default_cache_origin_request_policy_id
    realtime_log_config_arn    = var.default_cache_realtime_log_config_arn
    response_headers_policy_id = var.default_cache_response_headers_policy_id
    smooth_streaming           = var.default_cache_smooth_streaming
    target_origin_id           = var.default_cache_target_origin_id
    trusted_key_groups         = var.default_cache_trusted_key_groups
    trusted_signers            = var.default_cache_trusted_signers
    viewer_protocol_policy     = var.default_cache_viewer_protocol_policy
  }

  dynamic "logging_config" {
    for_each = var.logging_config != null ? var.logging_config : {}
    content {
      bucket          = logging_config.value.bucket
      include_cookies = logging_config.value.include_cookies
      prefix          = logging_config.value.prefix
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.ordered_cache_behavior != null ? var.ordered_cache_behavior : {}
    content {
      allowed_methods           = ordered_cache_behavior.value.allowed_methods
      cached_methods            = ordered_cache_behavior.value.cached_methods
      cache_policy_id           = ordered_cache_behavior.value.cache_policy_id
      compress                  = ordered_cache_behavior.value.compress
      field_level_encryption_id = ordered_cache_behavior.value.field_level_encryption_id
      # lambda_function_association block
      # function_association block
      origin_request_policy_id   = ordered_cache_behavior.value.origin_request_policy_id
      path_pattern               = ordered_cache_behavior.value.path_pattern
      realtime_log_config_arn    = ordered_cache_behavior.value.realtime_log_config_arn
      response_headers_policy_id = ordered_cache_behavior.value.response_headers_policy_id
      smooth_streaming           = ordered_cache_behavior.value.smooth_streaming
      target_origin_id           = ordered_cache_behavior.value.target_origin_id
      trusted_key_groups         = ordered_cache_behavior.value.trusted_key_groups
      trusted_signers            = ordered_cache_behavior.value.trusted_signers
      viewer_protocol_policy     = ordered_cache_behavior.value.viewer_protocol_policy
    }
  }

  dynamic "origin" {
    for_each = var.origins != null ? var.origins : {}
    content {
      connection_attempts = origin.value.connection_attempts
      connection_timeout  = origin.value.connection_timeout
      domain_name         = origin.value.domain_name
      origin_access_control_id = try(
        aws_cloudfront_origin_access_control.this[origin.value.origin_access_control_name].id,
        origin.value.origin_access_control_id,
        null
      )
      origin_id   = origin.key
      origin_path = origin.value.origin_path

      dynamic "custom_header" {
        for_each = origin.value.custom_headers != null ? origin.value.custom_headers : []
        content {
          name  = custom_header.header_name
          value = custom_header.header_value
        }
      }

      dynamic "custom_origin_config" {
        for_each = origin.value.custom_origin_config != null ? [true] : []
        content {
          http_port                = origin.value.custom_origin_config.http_port
          https_port               = origin.value.custom_origin_config.https_port
          origin_keepalive_timeout = origin.value.custom_origin_config.origin_keepalive_timeout
          origin_protocol_policy   = origin.value.custom_origin_config.origin_protocol_policy
          origin_read_timeout      = origin.value.custom_origin_config.origin_read_timeout
          origin_ssl_protocols     = origin.value.custom_origin_config.origin_ssl_protocols
        }
      }

      dynamic "origin_shield" {
        for_each = origin.value.origin_shield != null ? [true] : []
        content {
          enabled              = origin.value.origin_shield.enabled
          origin_shield_region = origin.value.origin_shield.origin_shield_region
        }
      }

      dynamic "s3_origin_config" {
        for_each = origin.value.s3_origin_config != null ? [true] : []
        content {
          origin_access_identity = origin.value.s3_origin_config.origin_access_identity
        }
      }
    }
  }

  restrictions {
    geo_restriction {
      locations        = var.geo_restriction_locations
      restriction_type = var.geo_restriction_type
    }
  }

  viewer_certificate {
    acm_certificate_arn            = try(aws_acm_certificate_validation.this[0].certificate_arn, var.acm_certificate_arn)
    cloudfront_default_certificate = var.cloudfront_default_certificate
    iam_certificate_id             = var.iam_certificate_id
    minimum_protocol_version       = var.ssl_minimum_protocol_version
    ssl_support_method             = var.ssl_support_method
  }

  lifecycle {
    # Fail fast on a dangling reference: every origins[*].origin_access_control_name
    # must match a key in var.origin_access_controls, otherwise the try() resolution
    # in the origin block would silently fall back to null (no OAC attached).
    precondition {
      condition = var.origins == null ? true : alltrue([
        for k, v in var.origins :
        v.origin_access_control_name == null ? true : contains(keys(var.origin_access_controls != null ? var.origin_access_controls : {}), v.origin_access_control_name)
      ])
      error_message = "Each origins[*].origin_access_control_name must match a key in var.origin_access_controls."
    }

    # Steer callers away from the ACM validation race condition. A custom ACM
    # certificate (acm_certificate_arn) must reach ISSUED before the
    # distribution is created. Terraform cannot tell a validated ARN from a raw
    # one at plan time, so this gate keys off the variable flags: either gate on
    # validation in-module (wait_for_certificate_validation), or use a non-ACM
    # certificate path (cloudfront_default_certificate / iam_certificate_id).
    precondition {
      condition = (
        var.acm_certificate_arn == null ||
        var.cloudfront_default_certificate ||
        var.iam_certificate_id != null ||
        var.wait_for_certificate_validation
      )
      error_message = "When using a custom ACM certificate, either set wait_for_certificate_validation = true, or pass acm_certificate_arn from an aws_acm_certificate_validation resource (not aws_acm_certificate) so CloudFront waits for ISSUED state."
    }
  }
}
