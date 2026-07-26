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
# Policy Group Linkages
###########################
resource "scalr_policy_group_linkage" "this" {
  for_each = var.linkages

  policy_group_id = each.value.policy_group_id
  environment_id  = each.value.environment_id
}
