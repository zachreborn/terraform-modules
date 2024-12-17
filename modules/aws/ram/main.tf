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

data "aws_organizations_organization" "current_org" {}


###########################
# Locals
###########################

###########################
# Module Configuration
###########################

resource "aws_ram_sharing_with_organization" "this" {
  count = var.enable_organization_sharing ? 1 : 0
}

resource "aws_ram_resource_share" "this" {
  allow_external_principals = var.allow_external_principals
  name                      = var.name
  permission_arns           = var.permission_arns
  tags                      = var.tags
}

resource "aws_ram_resource_association" "this" {
  resource_arn       = var.resource_arn
  resource_share_arn = aws_ram_resource_share.this.arn
}

resource "aws_ram_principal_association" "this" {
  principal          = var.principal != null ? var.principal : data.aws_organizations_organization.current_org.arn
  resource_share_arn = aws_ram_resource_share.this.arn
}
