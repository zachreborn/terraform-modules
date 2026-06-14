##############################
# Provider Configuration
##############################

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

##############################
# Data Sources
##############################

data "aws_iam_policy" "lookup" {
  count = var.policy_name != null ? 1 : 0
  name  = var.policy_name
}

##############################
# Locals
##############################

locals {
  resolved_arn = var.policy_name != null ? data.aws_iam_policy.lookup[0].arn : var.policy_arn
}

##############################
# Policy Attachment Configuration
##############################

resource "aws_iam_user_policy_attachment" "this" {
  policy_arn = local.resolved_arn
  user       = var.user

  lifecycle {
    precondition {
      condition     = (var.policy_arn != null) != (var.policy_name != null)
      error_message = "Exactly one of 'policy_arn' or 'policy_name' must be specified, but not both."
    }
  }
}
