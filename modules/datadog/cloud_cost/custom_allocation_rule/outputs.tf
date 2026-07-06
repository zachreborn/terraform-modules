###########################
# Resource Outputs
###########################

output "ids" {
  description = "Map of logical names to the IDs of the custom allocation rules."
  value       = { for k, v in datadog_custom_allocation_rule.this : k => v.id }
}

output "created" {
  description = "Map of logical names to the timestamps (ISO 8601) when the custom allocation rules were created."
  value       = { for k, v in datadog_custom_allocation_rule.this : k => v.created }
}

output "updated" {
  description = "Map of logical names to the timestamps (ISO 8601) when the custom allocation rules were last updated."
  value       = { for k, v in datadog_custom_allocation_rule.this : k => v.updated }
}

output "versions" {
  description = "Map of logical names to the version numbers of the custom allocation rules. Increments on each update."
  value       = { for k, v in datadog_custom_allocation_rule.this : k => v.version }
}

output "order_ids" {
  description = "Map of logical names to the order IDs of the custom allocation rules. Use the datadog_custom_allocation_rules resource (via enable_rule_order) to control evaluation order."
  value       = { for k, v in datadog_custom_allocation_rule.this : k => v.order_id }
}

output "rejected" {
  description = "Map of logical names to whether each custom allocation rule was rejected by the Datadog API during creation due to validation errors."
  value       = { for k, v in datadog_custom_allocation_rule.this : k => v.rejected }
}

output "last_modified_user_uuids" {
  description = "Map of logical names to the UUIDs of the users who last modified each custom allocation rule."
  value       = { for k, v in datadog_custom_allocation_rule.this : k => v.last_modified_user_uuid }
}

output "rule_order_id" {
  description = "The ID of the custom allocation rules ordering resource. Only set when enable_rule_order is true."
  value       = var.enable_rule_order ? datadog_custom_allocation_rules.this[0].id : null
}
