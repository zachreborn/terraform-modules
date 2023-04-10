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
# data "aws_caller_identity" "current" {}
# data "aws_region" "current" {}

###########################
# IAM Policies
###########################
resource "aws_iam_policy" "mfa_required" {
  name        = var.mfa_required_policy_name
  description = "Allows users to manage their own MFA settings"
  policy      = file("../iam_policies/mfa_required/mfa_required_policy.json")
}

###########################
# IAM Groups & Attachments
###########################
resource "aws_iam_group" "powerusers" {
  name = var.powerusers_group_name
}

resource "aws_iam_group_policy_attachment" "powerusers" {
  group      = aws_iam_group.powerusers.name
  policy_arn = var.powerusers_policy_arn
}

resource "aws_iam_group_policy_attachment" "powerusers_mfa" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  group      = aws_iam_group.powerusers.name
  policy_arn = aws_iam_policy.mfa_required.arn
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_group" "billing" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  name = var.billing_group_name
}

resource "aws_iam_group_policy_attachment" "billing" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  group      = aws_iam_group.billing.name
  policy_arn = var.billing_policy_arn
}

resource "aws_iam_group_policy_attachment" "billing_mfa" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  group      = aws_iam_group.billing.name
  policy_arn = aws_iam_policy.mfa_required.arn
}

resource "aws_iam_group" "readonly" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  name = var.readonly_group_name
}

resource "aws_iam_group_policy_attachment" "readonly" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  group      = aws_iam_group.readonly.name
  policy_arn = var.readonly_policy_arn
}

resource "aws_iam_group_policy_attachment" "readonly_mfa" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  group      = aws_iam_group.readonly.name
  policy_arn = aws_iam_policy.mfa_required.arn
}

resource "aws_iam_group" "system_admins" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  name = var.system_admins_group_name
}

resource "aws_iam_policy" "system_admins_policy" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  description = var.system_admins_description
  name        = var.system_admins_name
  path        = var.system_admins_path
  policy      = file("../iam_policies/system_admins/system-admins-policy.json")
}

resource "aws_iam_group_policy_attachment" "system_admins" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  group      = aws_iam_group.system_admins.name
  policy_arn = aws_iam_policy.system_admins_policy.arn
}

resource "aws_iam_group_policy_attachment" "system_admins_mfa" {
  #tfsec:ignore:aws-iam-no-policy-wildcards
  group      = aws_iam_group.system_admins.name
  policy_arn = aws_iam_policy.mfa_required.arn
}
