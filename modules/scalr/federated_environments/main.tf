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
# Federated Environments
###########################
resource "scalr_federated_environments" "this" {
  for_each = var.federated_environments

  environment_id         = each.value.environment_id
  federated_environments = each.value.federated_environments
}
