###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.3.0" # Optional attributes in the timeouts object.

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# CloudFormation Stack
###########################
resource "aws_cloudformation_stack" "this" {
  region             = var.region
  name               = var.name
  capabilities       = var.capabilities
  disable_rollback   = var.disable_rollback ? true : null
  iam_role_arn       = var.iam_role_arn
  notification_arns  = var.notification_arns
  on_failure         = var.disable_rollback ? null : var.on_failure
  parameters         = var.parameters
  policy_body        = var.policy_body
  policy_url         = var.policy_url
  tags               = merge(var.tags, { Name = var.name })
  template_body      = var.template_body
  template_url       = var.template_url
  timeout_in_minutes = var.timeout_in_minutes

  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  lifecycle {
    prevent_destroy = true

    precondition {
      condition     = (var.template_body != null) != (var.template_url != null)
      error_message = "Provide exactly one of template_body and template_url."
    }

    precondition {
      condition     = var.policy_body == null || var.policy_url == null
      error_message = "Provide at most one of policy_body and policy_url."
    }
  }
}
