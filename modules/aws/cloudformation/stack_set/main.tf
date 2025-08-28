###########################
# Provider Configuration
###########################
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


###########################
# Locals
###########################


###########################
# Module Configuration
###########################
resource "aws_cloudformation_stack_set" "this" {
  administration_role_arn = var.administration_role_arn
  call_as                 = var.call_as
  capabilities            = var.capabilities
  description             = var.description
  execution_role_name     = var.execution_role_name
  name                    = var.name
  parameters              = var.parameters
  permission_model        = var.permission_model
  tags                    = var.tags
  template_body           = var.template_body
  template_url            = var.template_url

  dynamic "auto_deployment" {
    for_each = var.enable_auto_deployment ? [1] : []
    content {
      enabled                          = true
      retain_stacks_on_account_removal = var.retain_stacks_on_account_removal
    }
  }

  dynamic "managed_execution" {
    for_each = var.enable_managed_execution ? [1] : []
    content {
      active = true
    }
  }

  operation_preferences {
    failure_tolerance_count      = var.failure_tolerance_percentage == null ? var.failure_tolerance_count : null
    failure_tolerance_percentage = var.failure_tolerance_percentage
    max_concurrent_count         = var.max_concurrent_percentage == null ? var.max_concurrent_count : null
    max_concurrent_percentage    = var.max_concurrent_percentage
    region_concurrency_type      = var.region_concurrency_type
    region_order                 = var.region_order
  }
}

# Stack Set Instances
# These are used to deploy a Stack Set across an AWS Organization based on OU or other parameters.

resource "aws_cloudformation_stack_set_instance" "this" {
  call_as        = var.call_as
  stack_set_name = aws_cloudformation_stack_set.this.name
  deployment_targets {
    accounts                = var.accounts
    account_filter_type     = var.account_filter_type
    accounts_url            = var.accounts_url
    organizational_unit_ids = var.organizational_unit_ids
  }
}
