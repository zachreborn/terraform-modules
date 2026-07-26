###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr Infracost integration IDs keyed by the same logical name used in var.infracost_integrations."
  value       = { for key, value in scalr_integration_infracost.this : key => value.id }
}

output "infracost_integrations" {
  description = "Map of scalr_integration_infracost resource objects (excluding the sensitive api_key attribute, which remains in state) keyed by the same logical name used in var.infracost_integrations."
  value = {
    for key, value in scalr_integration_infracost.this : key => {
      id           = value.id
      name         = value.name
      environments = value.environments
    }
  }
}
