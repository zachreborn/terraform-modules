###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of private location IDs keyed by logical name."
  value       = { for k, v in datadog_synthetics_private_location.this : k => v.id }
}

output "configs" {
  description = "Map of private location installation JSON configuration blobs keyed by logical name. These are sensitive and contain the credentials required to install the private location worker."
  value       = { for k, v in datadog_synthetics_private_location.this : k => v.config }
  sensitive   = true
}

output "restriction_policy_resource_ids" {
  description = "Map of resource IDs keyed by logical name, for use when setting restrictions with a datadog_restriction_policy resource."
  value       = { for k, v in datadog_synthetics_private_location.this : k => v.restriction_policy_resource_id }
}
