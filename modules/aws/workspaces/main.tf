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

  directories        = var.directories
  ip_group_id_lookup = module.ip_groups.ids
  tags               = var.tags
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

  workspaces             = var.workspaces
  directory_id_lookup    = module.directories.ids
  enable_default_kms_key = var.enable_default_kms_key
  kms_key_alias          = var.kms_key_alias
  tags                   = var.tags
}
