###########################
# Resource Outputs
###########################
output "id" {
  description = "The ID of the Synthetics concurrency cap resource."
  value       = datadog_synthetics_concurrency_cap.this.id
}
