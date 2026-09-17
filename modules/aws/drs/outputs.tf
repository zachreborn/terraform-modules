###########################
# Replication Configuration Template Outputs
###########################

output "replication_configuration_template_arns" {
  description = "Map of replication configuration template ARNs, keyed by the logical name used in var.templates."
  value       = module.replication_configuration_template.arns
}

output "replication_configuration_template_ids" {
  description = "Map of replication configuration template IDs, keyed by the logical name used in var.templates."
  value       = module.replication_configuration_template.ids
}

output "replication_configuration_templates" {
  description = "Map of the full replication configuration template resources, keyed by the logical name used in var.templates."
  value       = module.replication_configuration_template.templates
}

###########################
# KMS Key Outputs
###########################

output "kms_key_arn" {
  description = "ARN of the customer managed KMS key encrypting the replication staging area, whether created by this module or supplied via kms_key_arn. Null when neither create_kms_key nor kms_key_arn is set."
  value       = local.kms_key_arn
}

###########################
# Initialization Outputs
###########################

output "initialization_role_arns" {
  description = "Map of Elastic Disaster Recovery service role ARNs, keyed by role name. Empty when create_initialization or create_service_roles is false."
  value       = try(module.initialization[0].role_arns, {})
}

output "initialization_role_names" {
  description = "Map of Elastic Disaster Recovery service role names, keyed by role name. Empty when create_initialization or create_service_roles is false."
  value       = try(module.initialization[0].role_names, {})
}

output "initialization_instance_profile_arns" {
  description = "Map of instance profile ARNs for the EC2-assumed Elastic Disaster Recovery roles, keyed by role name. Empty when create_initialization or create_service_roles is false."
  value       = try(module.initialization[0].instance_profile_arns, {})
}

output "initialization_service_linked_role_arn" {
  description = "ARN of the AWSServiceRoleForElasticDisasterRecovery service-linked role. Null when create_initialization or create_service_linked_role is false."
  value       = try(module.initialization[0].service_linked_role_arn, null)
}
