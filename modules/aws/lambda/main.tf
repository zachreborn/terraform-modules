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

resource "aws_lambda_function" "lambda_function" {
  description = var.description
  environment {
    variables = var.variables
  }
  filename                       = var.filename
  function_name                  = var.function_name
  handler                        = var.handler
  memory_size                    = var.memory_size
  reserved_concurrent_executions = var.reserved_concurrent_executions
  role                           = var.role
  runtime                        = var.runtime
  source_code_hash               = var.source_code_hash
  tags                           = merge(tomap({ Name = var.function_name }), var.tags)
  timeout                        = var.timeout

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
}

/*resource "aws_lambda_permission" "allow_cloudwatch" {
    statement_id    = var.statement_id
    action          = var.action
    function_name   = aws_lambda_function.lambda_function.function_name
    principal       = var.principal
    source_arn      = var.source_arn
}
*/
