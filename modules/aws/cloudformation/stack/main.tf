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

locals {
  disable_rollback = var.on_failure == null ? var.disable_rollback : false
  on_failure       = var.disable_rollback ? null : var.on_failure
  policy_body      = var.policy_url == null ? var.policy_body : null
  policy_url       = var.policy_body == null ? var.policy_url : null
  template_body    = var.template_url == null ? var.template_body : null
  template_url     = var.template_body == null ? var.template_url : null
}

###########################
# Module Configuration
###########################


resource "aws_cloudformation_stack" "this" {
  capabilities       = var.capabilities
  disable_rollback   = local.disable_rollback
  iam_role_arn       = var.iam_role_arn
  name               = var.name
  notification_arns  = var.notification_arns
  on_failure         = local.on_failure
  parameters         = var.parameters
  policy_body        = local.policy_body
  policy_url         = local.policy_url
  tags               = var.tags
  template_body      = local.template_body
  template_url       = local.template_url
  timeout_in_minutes = var.timeout_in_minutes
}
