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


###########################
# Locals
###########################


###########################
# Module Configuration
###########################


resource "aws_cloudformation_stack" "this" {
  capabilities       = var.capabilities
  disable_rollback   = var.on_failure == null ? var.disable_rollback : false
  iam_role_arn       = var.iam_role_arn
  name               = var.name
  notification_arns  = var.notification_arns
  on_failure         = var.disable_rollback ? null : var.on_failure
  parameters         = var.parameters
  policy_body        = var.policy_url == null ? var.policy_body : null
  policy_url         = var.policy_body == null ? var.policy_url : null
  tags               = var.tags
  template_body      = var.template_url == null ? var.template_body : null
  template_url       = var.template_body == null ? var.template_url : null
  timeout_in_minutes = var.timeout_in_minutes
}
