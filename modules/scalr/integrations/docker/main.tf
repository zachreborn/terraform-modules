###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.9.0" # variable validations reference other variables (needs 1.9+)
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.20.0" # scalr_docker_integration first shipped in provider 3.20.0
    }
  }
}

###########################
# Scalr Docker Integration
###########################
resource "scalr_docker_integration" "this" {
  for_each = var.docker_integrations

  name               = each.value.name
  registry_url       = each.value.registry_url
  username           = each.value.username
  export_credentials = each.value.export_credentials
  # The password comes from the separate sensitive var.docker_passwords map. The cross-variable
  # validation on that variable guarantees a non-empty entry exists for every key in
  # var.docker_integrations, so a direct index is safe here.
  password = var.docker_passwords[each.key]
}
