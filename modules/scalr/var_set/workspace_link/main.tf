###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.9.0"
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.17.0"
    }
  }
}

###########################
# Scalr Workspace Var Set Link
###########################

resource "scalr_workspace_var_set" "this" {
  for_each = var.workspace_var_set_links

  workspace_id = each.value.workspace_id
  var_set_id   = each.value.var_set_id
}
