###########################
# Resource Outputs
###########################

output "arns" {
  description = "Map of replication configuration template ARNs, keyed by the logical name used in var.templates."
  value       = { for key, template in aws_drs_replication_configuration_template.this : key => template.arn }
}

output "ids" {
  description = "Map of replication configuration template IDs, keyed by the logical name used in var.templates."
  value       = { for key, template in aws_drs_replication_configuration_template.this : key => template.id }
}

output "ebs_encryption" {
  description = "Map of the resolved EBS encryption mode (DEFAULT, CUSTOM, or NONE) for each template, keyed by the logical name used in var.templates."
  value       = { for key, template in aws_drs_replication_configuration_template.this : key => template.ebs_encryption }
}

output "ebs_encryption_key_arns" {
  description = "Map of the KMS key ARN encrypting each template's staging area, keyed by the logical name used in var.templates. Null for templates using DEFAULT or NONE encryption."
  value       = { for key, template in aws_drs_replication_configuration_template.this : key => template.ebs_encryption_key_arn }
}

output "staging_area_subnet_ids" {
  description = "Map of the staging area subnet ID used by each template, keyed by the logical name used in var.templates."
  value       = { for key, template in aws_drs_replication_configuration_template.this : key => template.staging_area_subnet_id }
}

output "tags_all" {
  description = "Map of the full tag set applied to each template, including provider default_tags, keyed by the logical name used in var.templates."
  value       = { for key, template in aws_drs_replication_configuration_template.this : key => template.tags_all }
}

output "templates" {
  description = "Map of the full replication configuration template resources, keyed by the logical name used in var.templates."
  value       = aws_drs_replication_configuration_template.this
}
