terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Locals
###########################

locals {
  # Normalize bare/null organizational_units entries (YAML `workloads:` decodes to null, not {}) into
  # empty objects so their optional attributes can be inspected below. A plain conditional is used
  # instead of coalesce(), since coalesce() requires every argument to share the exact same static
  # type, and the declared object type (with its optional attributes) is not the same static type as
  # a bare `{}` literal.
  organizational_units_normalized = {
    for k, v in var.organizational_units : k => v != null ? v : {
      name       = null
      parent_id  = null
      parent_key = null
      tags       = {}
    }
  }

  # The managed Organization's default root ID, if var.organization was set.
  organization_root_id = try(module.organization["this"].roots[0].id, null)

  # Any entry with neither parent_id nor parent_key set defaults to the managed Organization's root.
  # Entries that already set one or the other are passed through unchanged.
  organizational_units_resolved = {
    for k, v in local.organizational_units_normalized : k => merge(v, {
      parent_id = (v.parent_id == null && v.parent_key == null) ? local.organization_root_id : v.parent_id
    })
  }
}

###########################
# Organization
###########################

module "organization" {
  source = "./organization"

  for_each = var.organization != null ? { this = var.organization } : {}

  allowed_regions                               = each.value.allowed_regions
  attach_identity_center_scp                    = each.value.attach_identity_center_scp
  attach_leave_organization_scp                 = each.value.attach_leave_organization_scp
  attach_region_scp                             = each.value.attach_region_scp
  attach_root_access_key_scp                    = each.value.attach_root_access_key_scp
  attach_root_actions_scp                       = each.value.attach_root_actions_scp
  attach_security_services_scp                  = each.value.attach_security_services_scp
  aws_service_access_principals                 = each.value.aws_service_access_principals
  enable_identity_center_scp                    = each.value.enable_identity_center_scp
  enable_leave_organization_scp                 = each.value.enable_leave_organization_scp
  enable_organization_backup                    = each.value.enable_organization_backup
  enable_region_scp                             = each.value.enable_region_scp
  enable_root_access_key_scp                    = each.value.enable_root_access_key_scp
  enable_root_actions_scp                       = each.value.enable_root_actions_scp
  enable_security_services_scp                  = each.value.enable_security_services_scp
  enabled_features                              = each.value.enabled_features
  enabled_policy_types                          = each.value.enabled_policy_types
  feature_set                                   = each.value.feature_set
  identity_center_scp_description               = each.value.identity_center_scp_description
  identity_center_scp_name                      = each.value.identity_center_scp_name
  identity_center_scp_target_ids                = each.value.identity_center_scp_target_ids
  leave_organization_scp_description            = each.value.leave_organization_scp_description
  leave_organization_scp_name                   = each.value.leave_organization_scp_name
  leave_organization_scp_target_ids             = each.value.leave_organization_scp_target_ids
  region_scp_description                        = each.value.region_scp_description
  region_scp_exempted_actions                   = each.value.region_scp_exempted_actions
  region_scp_exempted_principal_arns            = each.value.region_scp_exempted_principal_arns
  region_scp_name                               = each.value.region_scp_name
  region_scp_target_ids                         = each.value.region_scp_target_ids
  root_access_key_scp_description               = each.value.root_access_key_scp_description
  root_access_key_scp_name                      = each.value.root_access_key_scp_name
  root_access_key_scp_target_ids                = each.value.root_access_key_scp_target_ids
  root_actions_scp_description                  = each.value.root_actions_scp_description
  root_actions_scp_exempted_actions             = each.value.root_actions_scp_exempted_actions
  root_actions_scp_name                         = each.value.root_actions_scp_name
  root_actions_scp_target_ids                   = each.value.root_actions_scp_target_ids
  security_services_scp_description             = each.value.security_services_scp_description
  security_services_scp_exempted_principal_arns = each.value.security_services_scp_exempted_principal_arns
  security_services_scp_name                    = each.value.security_services_scp_name
  security_services_scp_target_ids              = each.value.security_services_scp_target_ids
  tags                                          = each.value.tags
}

###########################
# Organizational Units
###########################

module "organizational_units" {
  source = "./ou"

  organizational_units = local.organizational_units_resolved
  tags                 = var.tags
}

###########################
# Accounts
###########################

module "accounts" {
  source = "./account"

  accounts                = var.accounts
  organizational_unit_ids = module.organizational_units.ids
  tags                    = var.tags
}
