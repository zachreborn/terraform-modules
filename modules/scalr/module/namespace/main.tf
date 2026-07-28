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
# Module Namespaces
###########################
resource "scalr_module_namespace" "this" {
  for_each = var.module_namespaces

  name         = coalesce(each.value.name, each.key)
  environments = each.value.environments
  is_shared    = each.value.is_shared
  owners       = each.value.owners
}
