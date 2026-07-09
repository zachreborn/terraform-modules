###########################
# Resource Outputs
###########################

output "arns" {
  description = "Map of secret ARNs, keyed by the same logical name used in var.secrets."
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.arn }
}

output "ids" {
  description = "Map of secret IDs (ARNs), keyed by the same logical name used in var.secrets."
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.id }
}

output "version_ids" {
  description = "Map of secret version IDs, keyed by the same logical name used in var.secret_values."
  value       = { for k, v in aws_secretsmanager_secret_version.this : k => v.version_id }
}

output "rotation_enabled" {
  description = "Map indicating whether automatic rotation is enabled, keyed by the same logical name used in var.secrets."
  value       = { for k, v in aws_secretsmanager_secret_rotation.this : k => v.rotation_enabled }
}

output "kms_key_arns" {
  description = "Map of composed customer managed KMS key ARNs, keyed by the same logical name used in var.secrets. Only includes entries where create_kms_key is true."
  value       = { for k, v in module.kms_key : k => v.arn }
}
