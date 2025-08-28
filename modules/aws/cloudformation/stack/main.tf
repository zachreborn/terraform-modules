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
  template_body      = var.template_file
  template_url       = var.template_url
  timeout_in_minutes = var.timeout_in_minutes
}
