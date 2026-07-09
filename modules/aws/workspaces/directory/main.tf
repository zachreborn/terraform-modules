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
  # aws_workspaces_directory's CustomizeDiff hard-errors if workspace_creation_properties.
  # enable_maintenance_mode or .user_enabled_as_local_administrator is true while workspace_type is POOLS.
  # Both default to true/false independently of workspace_type in the object type below (the true default
  # on enable_maintenance_mode is PERSONAL-oriented secure-by-default guidance), so force both to false for
  # POOLS entries here rather than relying on every caller to override them -- the plain object default
  # would otherwise break every POOLS entry that doesn't explicitly set workspace_creation_properties.
  workspace_creation_properties = {
    for k, v in var.directories : k => merge(v.workspace_creation_properties, {
      enable_maintenance_mode             = v.workspace_type == "POOLS" ? false : v.workspace_creation_properties.enable_maintenance_mode
      user_enabled_as_local_administrator = v.workspace_type == "POOLS" ? false : v.workspace_creation_properties.user_enabled_as_local_administrator
    })
  }
}

###########################
# WorkSpaces Directories
###########################

resource "aws_workspaces_directory" "this" {
  for_each = var.directories

  directory_id                    = each.value.directory_id
  ip_group_ids                    = each.value.ip_group_ids
  subnet_ids                      = each.value.subnet_ids
  tags                            = merge(var.tags, each.value.tags)
  tenancy                         = each.value.tenancy
  workspace_type                  = each.value.workspace_type
  workspace_directory_name        = each.value.workspace_directory_name
  workspace_directory_description = each.value.workspace_directory_description
  user_identity_type              = each.value.user_identity_type

  dynamic "active_directory_config" {
    for_each = each.value.active_directory_config != null ? [each.value.active_directory_config] : []
    content {
      domain_name                = active_directory_config.value.domain_name
      service_account_secret_arn = active_directory_config.value.service_account_secret_arn
    }
  }

  dynamic "certificate_based_auth_properties" {
    for_each = each.value.certificate_based_auth_properties != null ? [each.value.certificate_based_auth_properties] : []
    content {
      certificate_authority_arn = certificate_based_auth_properties.value.certificate_authority_arn
      status                    = certificate_based_auth_properties.value.status
    }
  }

  dynamic "saml_properties" {
    for_each = each.value.saml_properties != null ? [each.value.saml_properties] : []
    content {
      relay_state_parameter_name = saml_properties.value.relay_state_parameter_name
      status                     = saml_properties.value.status
      user_access_url            = saml_properties.value.user_access_url
    }
  }

  # self_service_permissions only applies to PERSONAL directories -- AWS rejects the block for POOLS directories.
  dynamic "self_service_permissions" {
    for_each = each.value.workspace_type == "PERSONAL" ? [each.value.self_service_permissions] : []
    content {
      change_compute_type  = self_service_permissions.value.change_compute_type
      increase_volume_size = self_service_permissions.value.increase_volume_size
      rebuild_workspace    = self_service_permissions.value.rebuild_workspace
      restart_workspace    = self_service_permissions.value.restart_workspace
      switch_running_mode  = self_service_permissions.value.switch_running_mode
    }
  }

  workspace_access_properties {
    device_type_android    = each.value.workspace_access_properties.device_type_android
    device_type_chromeos   = each.value.workspace_access_properties.device_type_chromeos
    device_type_ios        = each.value.workspace_access_properties.device_type_ios
    device_type_linux      = each.value.workspace_access_properties.device_type_linux
    device_type_osx        = each.value.workspace_access_properties.device_type_osx
    device_type_web        = each.value.workspace_access_properties.device_type_web
    device_type_windows    = each.value.workspace_access_properties.device_type_windows
    device_type_zeroclient = each.value.workspace_access_properties.device_type_zeroclient
  }

  workspace_creation_properties {
    custom_security_group_id            = each.value.workspace_creation_properties.custom_security_group_id
    default_ou                          = local.workspace_creation_properties[each.key].default_ou
    enable_internet_access              = each.value.workspace_creation_properties.enable_internet_access
    enable_maintenance_mode             = local.workspace_creation_properties[each.key].enable_maintenance_mode
    user_enabled_as_local_administrator = local.workspace_creation_properties[each.key].user_enabled_as_local_administrator
  }
}
