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

  content     = file("${path.module}/policies/enable_backup_policy.json")
  description = "Centralized AWS Backup Policy for managing backup plans across the organization."
  name        = "Root"
  type        = "BACKUP_POLICY"
  tags        = var.tags
}

###########################################################
# Identity Center Service Control Policy
###########################################################

locals {
  # Targets the SCP is attached to. Defaults to the organization root when no
  # explicit targets are supplied and attachment is enabled.
  identity_center_scp_attachment_target_ids = (
    var.enable_identity_center_scp && var.attach_identity_center_scp
    ? (
      var.identity_center_scp_target_ids != null
      ? var.identity_center_scp_target_ids
      : [aws_organizations_organization.org.roots[0].id]
    )
    : []
  )
}

module "identity_center_scp" {
  source = "../policy"

  for_each = var.enable_identity_center_scp ? { "identity_center_scp" = "true" } : {}

  content     = file("${path.module}/policies/deny_identity_center_instance_scp.json")
  description = var.identity_center_scp_description
  name        = var.identity_center_scp_name
  type        = "SERVICE_CONTROL_POLICY"
  tags        = var.tags
}

resource "aws_organizations_policy_attachment" "identity_center_scp" {
  for_each = toset(local.identity_center_scp_attachment_target_ids)

  policy_id = module.identity_center_scp["identity_center_scp"].id
  target_id = each.value

  lifecycle {
    precondition {
      condition     = !var.enable_identity_center_scp || contains(coalesce(var.enabled_policy_types, []), "SERVICE_CONTROL_POLICY")
      error_message = "enable_identity_center_scp is true but \"SERVICE_CONTROL_POLICY\" is not present in enabled_policy_types. Add \"SERVICE_CONTROL_POLICY\" to enabled_policy_types so the Identity Center SCP can be created and attached."
    }
  }
}
