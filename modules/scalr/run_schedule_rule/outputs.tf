###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr run schedule rule IDs keyed by the same logical name used in var.run_schedule_rules."
  value       = { for key, value in scalr_run_schedule_rule.this : key => value.id }
}

output "run_schedule_rules" {
  description = "Map of full scalr_run_schedule_rule resource objects keyed by the same logical name used in var.run_schedule_rules."
  value       = { for key, value in scalr_run_schedule_rule.this : key => value }
}
