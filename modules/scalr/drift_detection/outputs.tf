###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Scalr drift detection scheduler IDs keyed by the same logical name used in var.drift_detections."
  value       = { for key, value in scalr_drift_detection.this : key => value.id }
}

output "drift_detections" {
  description = "Map of full scalr_drift_detection resource objects keyed by the same logical name used in var.drift_detections."
  value       = { for key, value in scalr_drift_detection.this : key => value }
}
