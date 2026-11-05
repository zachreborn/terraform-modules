###########################
# Resource Outputs
###########################
# Explicit non-sensitive projections only. The whole scalr_wiz_integration object is deliberately
# NOT output because it carries the sensitive client_secret attribute.
output "ids" {
  description = "Map of Scalr Wiz integration IDs (in-<RANDOM STRING>) keyed by the same logical name used in var.wiz_integrations."
  value       = { for key, value in scalr_wiz_integration.this : key => value.id }
}
