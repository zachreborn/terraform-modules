terraform {
  # >= 1.3.0 because the vpc_config variable type uses an optional() attribute in its object type.
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Locals
###########################

locals {
  # Container-image functions take their entrypoint and runtime from the image, and the
  # provider rejects `handler` and `runtime` for them, so both are forced to null below.
  is_image = var.package_type == "Image"
}

###########################
# Lambda Function
###########################

resource "aws_lambda_function" "lambda_function" {
  architectures = var.architectures
  description   = var.description
  environment {
    variables = var.variables
  }
  filename                       = var.filename
  function_name                  = var.function_name
  handler                        = local.is_image ? null : var.handler
  image_uri                      = var.image_uri
  memory_size                    = var.memory_size
  package_type                   = var.package_type
  reserved_concurrent_executions = var.reserved_concurrent_executions
  role                           = var.role
  runtime                        = local.is_image ? null : var.runtime
  source_code_hash               = var.source_code_hash
  tags                           = merge(tomap({ Name = var.function_name }), var.tags)
  timeout                        = var.timeout

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_size == null ? [] : [var.ephemeral_storage_size]
    content {
      size = ephemeral_storage.value
    }
  }

  dynamic "image_config" {
    for_each = var.image_config == null ? [] : [var.image_config]
    content {
      command           = image_config.value.command
      entry_point       = image_config.value.entry_point
      working_directory = image_config.value.working_directory
    }
  }

  dynamic "vpc_config" {
    for_each = var.vpc_config == null ? [] : [var.vpc_config]
    content {
      subnet_ids                  = vpc_config.value.subnet_ids
      security_group_ids          = vpc_config.value.security_group_ids
      ipv6_allowed_for_dual_stack = vpc_config.value.ipv6_allowed_for_dual_stack
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config == null ? [] : [var.dead_letter_config]
    content {
      target_arn = dead_letter_config.value.target_arn
    }
  }

  dynamic "tracing_config" {
    for_each = var.tracing_config == null ? [] : [var.tracing_config]
    content {
      mode = tracing_config.value.mode
    }
  }

  # Cross-variable checks live here (not in variable validation blocks) so the module keeps
  # working on OpenTofu/Terraform 1.3+; cross-variable validation needs 1.9+.
  lifecycle {
    precondition {
      condition     = !local.is_image || var.image_uri != null
      error_message = "image_uri is required when package_type is \"Image\"."
    }

    precondition {
      condition     = var.image_uri == null || local.is_image
      error_message = "image_uri can only be set when package_type is \"Image\"."
    }

    precondition {
      condition     = !local.is_image || var.filename == null
      error_message = "filename cannot be set when package_type is \"Image\"; use image_uri instead."
    }
  }
}

/*resource "aws_lambda_permission" "allow_cloudwatch" {
    statement_id    = var.statement_id
    action          = var.action
    function_name   = aws_lambda_function.lambda_function.function_name
    principal       = var.principal
    source_arn      = var.source_arn
}
*/
