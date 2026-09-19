###########################
# Resource Outputs
###########################

output "id" {
  description = "The ID of the Cloud Map HTTP namespace."
  value       = aws_service_discovery_http_namespace.this.id
}

output "arn" {
  description = "The ARN of the Cloud Map HTTP namespace. Referenced by the cluster (service_connect_defaults) and services (service_connect_configuration)."
  value       = aws_service_discovery_http_namespace.this.arn
}

output "name" {
  description = "The name of the Cloud Map HTTP namespace."
  value       = aws_service_discovery_http_namespace.this.name
}
