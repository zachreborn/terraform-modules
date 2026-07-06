###########################
# AWS CUR Config Outputs
###########################
output "aws_cur_config_ids" {
  description = "Map of logical names to the IDs of the AWS CUR configurations."
  value       = module.aws_cur_config.ids
}

output "aws_cur_config_statuses" {
  description = "Map of logical names to the current status of each AWS CUR configuration."
  value       = module.aws_cur_config.statuses
}

output "aws_cur_config_status_updated_ats" {
  description = "Map of logical names to the timestamps when each configuration status was last updated."
  value       = module.aws_cur_config.status_updated_ats
}

output "aws_cur_config_created_ats" {
  description = "Map of logical names to the timestamps when each AWS CUR configuration was created."
  value       = module.aws_cur_config.created_ats
}

output "aws_cur_config_updated_ats" {
  description = "Map of logical names to the timestamps when each AWS CUR configuration was last modified."
  value       = module.aws_cur_config.updated_ats
}

output "aws_cur_config_error_messages" {
  description = "Map of logical names to lists of error messages for each AWS CUR configuration."
  value       = module.aws_cur_config.error_messages
}

###########################
# AWS CCM Config Outputs
###########################
output "ccm_config_ids" {
  description = "Map of logical names to the IDs of the CCM configurations."
  value       = module.aws_ccm_config.ids
}

###########################
# Budget Outputs
###########################
output "budget_ids" {
  description = "Map of logical names to the IDs of the cost budgets."
  value       = module.budget.ids
}

output "budget_total_amounts" {
  description = "Map of logical names to the total amount (sum of all budget entries) for each budget."
  value       = module.budget.total_amounts
}

###########################
# Custom Allocation Rule Outputs
###########################
output "allocation_rule_ids" {
  description = "Map of logical names to the IDs of the custom allocation rules."
  value       = module.custom_allocation_rule.ids
}

output "allocation_rule_created" {
  description = "Map of logical names to the timestamps (ISO 8601) when the custom allocation rules were created."
  value       = module.custom_allocation_rule.created
}

output "allocation_rule_updated" {
  description = "Map of logical names to the timestamps (ISO 8601) when the custom allocation rules were last updated."
  value       = module.custom_allocation_rule.updated
}

output "allocation_rule_versions" {
  description = "Map of logical names to the version numbers of the custom allocation rules."
  value       = module.custom_allocation_rule.versions
}

output "allocation_rule_order_ids" {
  description = "Map of logical names to the order IDs of the custom allocation rules."
  value       = module.custom_allocation_rule.order_ids
}

output "allocation_rule_rejected" {
  description = "Map of logical names to whether each custom allocation rule was rejected by the Datadog API during creation."
  value       = module.custom_allocation_rule.rejected
}

output "allocation_rule_last_modified_user_uuids" {
  description = "Map of logical names to the UUIDs of the users who last modified each custom allocation rule."
  value       = module.custom_allocation_rule.last_modified_user_uuids
}

output "rule_order_id" {
  description = "The ID of the custom allocation rules ordering resource. Only set when config.enable_rule_order is true."
  value       = module.custom_allocation_rule.rule_order_id
}
