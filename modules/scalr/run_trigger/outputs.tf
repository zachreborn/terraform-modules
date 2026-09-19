###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr run trigger IDs keyed by the same logical name used in var.run_triggers."
  value       = { for key, value in scalr_run_trigger.this : key => value.id }
}

output "run_triggers" {
  description = "Map of full scalr_run_trigger resource objects keyed by the same logical name used in var.run_triggers."
  value       = { for key, value in scalr_run_trigger.this : key => value }
}
