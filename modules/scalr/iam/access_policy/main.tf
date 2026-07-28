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
# Data Sources
###########################


###########################
# Locals
###########################


###########################
# Module Configuration
###########################
resource "scalr_access_policy" "this" {
  for_each = var.access_policies

  role_ids = each.value.role_ids

  scope {
    id   = each.value.scope.id
    type = each.value.scope.type
  }

  subject {
    id   = each.value.subject.id
    type = each.value.subject.type
  }
}
