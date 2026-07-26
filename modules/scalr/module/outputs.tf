###########################
# Resource Outputs
###########################
output "ids" {
  description = "Map of Module IDs, keyed by the same keys as var.modules."
  value       = { for k, v in scalr_module.this : k => v.id }
}

output "sources" {
  description = "Map of the source of each remote module in the private registry (e.g. \"env-xxxx/aws/vpc\"), keyed by the same keys as var.modules."
  value       = { for k, v in scalr_module.this : k => v.source }
}

output "statuses" {
  description = "Map of Module system statuses, keyed by the same keys as var.modules."
  value       = { for k, v in scalr_module.this : k => v.status }
}

output "namespace_ids" {
  description = "Map of Module Namespace IDs (from the companion ./namespace submodule), keyed by the same keys as var.module_namespaces."
  value       = module.namespace.ids
}

output "resolved_namespace_ids" {
  description = "Map of the namespace_id actually passed to each scalr_module entry, keyed by the same keys as var.modules. Useful to verify composition wiring."
  value       = local.resolved_namespace_ids
}
