terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.0.0"
      configuration_aliases = [aws.organization_management_account, aws.organization_security_account]
    }
  }
}

resource "aws_securityhub_account" "this" {
  enable_default_standards = var.enable_default_standards
}

resource "aws_securityhub_organization_admin_account" "this" {
  depends_on = [aws_securityhub_account.this]

  admin_account_id = var.admin_account_id
}

resource "aws_securityhub_organization_configuration" "this" {
  auto_enable           = var.auto_enable
  auto_enable_standards = var.auto_enable_standards
}
