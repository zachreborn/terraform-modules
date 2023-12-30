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

data "aws_ssoadmin_instances" "this" {}

###########################
# Locals
###########################

###########################
# Permission Set
###########################

resource "aws_ssoadmin_permission_set" "this" {
  name             = var.name
  description      = var.description
  instance_arn     = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  relay_state      = var.relay_state
  session_duration = var.session_duration
  tags             = merge(var.tags, { "Name" = var.name })
}

resource "aws_ssoadmin_customer_managed_policy_attachment" "this" {
  count              = var.customer_managed_iam_policy_name != null ? 1 : 0
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
  customer_managed_policy_reference {
    name = var.customer_managed_iam_policy_name
    path = var.customer_managed_iam_policy_path
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "this" {
  count              = var.managed_policy_arn != null ? 1 : 0
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  managed_policy_arn = var.managed_policy_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
}

resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  count              = var.inline_policy != null ? 1 : 0
  inline_policy      = var.inline_policy
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn
}
