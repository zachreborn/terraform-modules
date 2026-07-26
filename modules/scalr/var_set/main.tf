###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
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
  # Resolve each workspace_links entry's var_set_id: a literal var_set_id passes through unchanged; a
  # var_set_key looks up the ID of a scalr_var_set created by this same module call (var.var_sets).
  workspace_links_resolved = {
    for k, v in var.workspace_links : k => {
      workspace_id = v.workspace_id
      var_set_id   = v.var_set_id != null ? v.var_set_id : scalr_var_set.this[v.var_set_key].id
    }
  }
}

###########################
# Scalr Var Set
###########################

resource "scalr_var_set" "this" {
  for_each = var.var_sets

  name         = coalesce(each.value.name, each.key)
  description  = each.value.description
  environments = each.value.environments
  owners       = each.value.owners
}

###########################
# Scalr Workspace Var Set Links (composition)
###########################

module "workspace_link" {
  source = "./workspace_link"

  workspace_var_set_links = local.workspace_links_resolved
}
