###########################
# Resource Outputs
###########################

output "ids" {
  description = "Map of logical names to the IDs of the AWS CUR configurations."
  value       = { for k, v in datadog_aws_cur_config.this : k => v.id }
}

output "statuses" {
  description = "Map of logical names to the current status of each AWS CUR configuration."
  value       = { for k, v in datadog_aws_cur_config.this : k => v.status }
}

output "status_updated_ats" {
  description = "Map of logical names to the timestamps when each configuration status was last updated."
  value       = { for k, v in datadog_aws_cur_config.this : k => v.status_updated_at }
}

output "created_ats" {
  description = "Map of logical names to the timestamps when each AWS CUR configuration was created."
  value       = { for k, v in datadog_aws_cur_config.this : k => v.created_at }
}

output "updated_ats" {
  description = "Map of logical names to the timestamps when each AWS CUR configuration was last modified."
  value       = { for k, v in datadog_aws_cur_config.this : k => v.updated_at }
}

output "error_messages" {
  description = "Map of logical names to lists of error messages for each AWS CUR configuration."
  value       = { for k, v in datadog_aws_cur_config.this : k => v.error_messages }
}
