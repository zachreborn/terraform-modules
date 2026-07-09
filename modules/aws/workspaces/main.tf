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
  # Resolve each directories entry's ip_group_ids by merging any literal IDs with IDs looked up from
  # ip_group_keys (keys into var.ip_groups, resolved through the ip_groups child module's own ids output).
  # This mirrors the parent_id/parent_key pattern used by modules/aws/organizations/account.
  directories_resolved = {
    for k, v in var.directories : k => merge(v, {
      ip_group_ids = distinct(concat(
        v.ip_group_ids,
        [for ip_group_key in v.ip_group_keys : module.ip_groups.ids[ip_group_key]]
      ))
    })
  }

  # Resolve each workspaces entry's directory_id from directory_key (a key into var.directories, resolved
  # through the directory child module's own ids output) when a literal directory_id was not supplied.
  workspaces_resolved = {
    for k, v in var.workspaces : k => merge(v, {
      directory_id = v.directory_key != null ? module.directories.ids[v.directory_key] : v.directory_id
    })
  }
}

###########################
# Service Role
###########################

module "service_role" {
  source = "./service_role"

  for_each = var.enable_service_role ? { this = true } : {}

  name                       = var.service_role_name
  enable_self_service_access = var.enable_self_service_access
  tags                       = var.tags
}

###########################
# IP Access Control Groups
###########################

module "ip_groups" {
  source = "./ip_group"

  ip_groups = var.ip_groups
  tags      = var.tags
}

###########################
# Directories
###########################

module "directories" {
  source = "./directory"

  directories = local.directories_resolved
  tags        = var.tags
}

###########################
# Connection Aliases
###########################

module "connection_aliases" {
  source = "./connection_alias"

  connection_aliases = var.connection_aliases
  tags               = var.tags
}

###########################
# Desktops
###########################

module "workspaces" {
  source = "./workspace"

  workspaces             = local.workspaces_resolved
  enable_default_kms_key = var.enable_default_kms_key
  kms_key_alias          = var.kms_key_alias
  tags                   = var.tags
}
