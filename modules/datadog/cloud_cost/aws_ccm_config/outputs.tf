###########################
# Resource Outputs
###########################

output "ids" {
  description = "Map of logical names to the IDs of the CCM configurations."
  value       = { for k, v in datadog_integration_aws_account_ccm_config.this : k => v.id }
}
