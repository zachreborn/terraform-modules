terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.78.0"
    }
  }
}

###########################################################
# AWS Organization
###########################################################

resource "aws_organizations_organization" "org" {
  aws_service_access_principals = var.aws_service_access_principals
  enabled_policy_types          = var.enabled_policy_types
  feature_set                   = var.feature_set

  lifecycle {
    prevent_destroy = true
  }
}

###########################################################
# Centralized Root Management
###########################################################
module "centralized_root" {
  source = "../../iam/organizations_features"

  enabled_features = var.enabled_features
}

###########################################################
# Centralized AWS Backup Management
###########################################################

module "centralized_backup" {
  source = "../policy"

  for_each = var.enable_organization_backup ? { "backup_policy" = "true" } : {}

  content     = file("policies/enable_backup_policy.json")
  description = "Centralized AWS Backup Policy for managing backup plans across the organization."
  name        = "Root"
  type        = "BACKUP_POLICY"
  tags        = var.tags
}
