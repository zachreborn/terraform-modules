###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Module Namespace IDs, keyed by the same keys as var.module_namespaces."
  value       = { for k, v in scalr_module_namespace.this : k => v.id }
}
