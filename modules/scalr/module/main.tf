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
      source = "registry.scalr.io/scalr/scalr"
      # >= 3.20.0: scalr_module's docker_image / docker_integration_id arguments (OCI-sourced modules)
      # and the source_type attribute were first released in provider v3.20.0.
      version = ">= 3.20.0"
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

  # VCS-sourced modules set vcs_provider_id + the vcs_repo block; OCI-sourced modules set
  # docker_image + docker_integration_id. variables.tf validates that exactly one source is chosen.
  vcs_provider_id       = each.value.vcs_provider_id
  docker_image          = each.value.docker_image
  docker_integration_id = each.value.docker_integration_id
  namespace_id          = local.resolved_namespace_ids[each.key]
  module_provider       = each.value.module_provider
  name                  = each.value.name
  # account_id and environment_id are deprecated by the upstream provider in favor of
  # namespace_id, but are still exposed here for full argument coverage (AGENTS.md Module
  # Design Specifications, Complete Resource Coverage).
  account_id     = each.value.account_id
  environment_id = each.value.environment_id

  # Rendered only for VCS-sourced entries. The provider documents vcs_repo as conflicting with
  # docker_image, so the block must be absent (not empty) for OCI-sourced entries. A dynamic block
  # does not change the resource's state address, so existing callers are unaffected.
  dynamic "vcs_repo" {
    for_each = each.value.vcs_repo != null ? [each.value.vcs_repo] : []
    content {
      identifier = vcs_repo.value.identifier
      path       = vcs_repo.value.path
      tag_prefix = vcs_repo.value.tag_prefix
    }
  }
}
