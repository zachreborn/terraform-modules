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
  # Validation checks for mutually exclusive parameters
  template_conflict = var.template_body != null && var.template_url != null
  policy_conflict   = var.policy_body != null && var.policy_url != null
  rollback_conflict = var.disable_rollback == true && var.on_failure != "ROLLBACK"
}

###########################
# Module Configuration
###########################

# Validation checks
check "template_conflict" {
  assert {
    condition     = !local.template_conflict
    error_message = "template_body and template_url are mutually exclusive - only one can be specified."
  }
}

check "policy_conflict" {
  assert {
    condition     = !local.policy_conflict
    error_message = "policy_body and policy_url are mutually exclusive - only one can be specified."
  }
}

check "rollback_conflict" {
  assert {
    condition     = !local.rollback_conflict
    error_message = "disable_rollback cannot be true when on_failure is set to anything other than ROLLBACK."
  }
}

resource "aws_cloudformation_stack" "this" {
  capabilities       = var.capabilities
  disable_rollback   = var.disable_rollback
  iam_role_arn       = var.iam_role_arn
  name               = var.name
  notification_arns  = var.notification_arns
  on_failure         = var.on_failure
  parameters         = var.parameters
  policy_body        = var.policy_body
  policy_url         = var.policy_url
  tags               = var.tags
  template_body      = var.template_body
  template_url       = var.template_url
  timeout_in_minutes = var.timeout_in_minutes
}
