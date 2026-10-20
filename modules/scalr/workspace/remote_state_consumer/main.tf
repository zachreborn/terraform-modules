###########################
# Provider Configuration
###########################
terraform {
  # variables.tf uses `nullable = false` (Terraform 1.1) and its validations reference only their own variable, so
  # the cross-variable validation floor (1.9) does not apply here.
  required_version = ">= 1.1.0"
  required_providers {
    scalr = {
      source = "registry.scalr.io/scalr/scalr"
      # scalr_workspace_remote_state_consumer was introduced in provider v3.20.0.
      version = ">= 3.20.0"
    }
  }
}

###########################
# Scalr Workspace Remote State Consumer
###########################
resource "scalr_workspace_remote_state_consumer" "this" {
  for_each = var.workspace_remote_state_consumers

  workspace_id = each.value.workspace_id
  consumer_id  = each.value.consumer_id
}
