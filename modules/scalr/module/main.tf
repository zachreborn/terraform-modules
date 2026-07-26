###########################
# Provider Configuration
###########################
terraform {
  # >= 1.9.0 is required because this module's namespace_key validation (variables.tf) references
  # var.module_namespaces from within the validation block for var.modules. Terraform and OpenTofu
  # both added support for referencing other variables/locals in variable validation in their
  # respective 1.9.0 releases, so this floor is satisfied by either tool.
  required_version = ">= 1.9.0"
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.17.0"
    }
  }
}

###########################
# Locals
###########################
locals {
  # Resolve each modules entry's namespace_id: either a literal namespace ID, or a reference (by
  # key) to a module namespace created by this same module call.
  resolved_namespace_ids = {
    for k, v in var.modules : k => v.namespace_key != null ? module.namespace.ids[v.namespace_key] : v.namespace_id
  }
}

###########################
# Module Namespaces (companion submodule)
###########################
module "namespace" {
  source = "./namespace"

  module_namespaces = var.module_namespaces
}

###########################
# Modules (Private Module Registry)
###########################
resource "scalr_module" "this" {
  for_each = var.modules

  vcs_provider_id = each.value.vcs_provider_id
  namespace_id    = local.resolved_namespace_ids[each.key]
  module_provider = each.value.module_provider
  name            = each.value.name
  # account_id and environment_id are deprecated by the upstream provider in favor of
  # namespace_id, but are still exposed here for full argument coverage (AGENTS.md Module
  # Design Specifications, Complete Resource Coverage).
  account_id     = each.value.account_id
  environment_id = each.value.environment_id

  vcs_repo {
    identifier = each.value.vcs_repo.identifier
    path       = each.value.vcs_repo.path
    tag_prefix = each.value.vcs_repo.tag_prefix
  }
}
