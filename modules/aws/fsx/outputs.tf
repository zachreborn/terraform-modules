###########################
# Resource Outputs
###########################

output "id" {
  description = "The identifier of the FSx for Windows File Server file system."
  value       = aws_fsx_windows_file_system.this.id
}

output "arn" {
  description = "The Amazon Resource Name (ARN) of the file system. Used as the location_arn when associating the file system with an FSx File Gateway."
  value       = aws_fsx_windows_file_system.this.arn
}

output "dns_name" {
  description = "The DNS name for the file system."
  value       = aws_fsx_windows_file_system.this.dns_name
}

output "preferred_file_server_ip" {
  description = "The IP address of the primary, or preferred, file server. Use this IP for SMB clients that connect by IP rather than DNS name."
  value       = aws_fsx_windows_file_system.this.preferred_file_server_ip
}

output "network_interface_ids" {
  description = "The set of Elastic Network Interface IDs from which the file system is accessible."
  value       = aws_fsx_windows_file_system.this.network_interface_ids
}

output "vpc_id" {
  description = "The identifier of the Virtual Private Cloud for the file system."
  value       = aws_fsx_windows_file_system.this.vpc_id
}

output "owner_id" {
  description = "The AWS account identifier that owns the file system."
  value       = aws_fsx_windows_file_system.this.owner_id
}

output "remote_administration_endpoint" {
  description = "For MULTI_AZ_1 deployment types, use this endpoint when performing administrative tasks on the file system using Amazon FSx Remote PowerShell. For SINGLE_AZ_1 and SINGLE_AZ_2 deployment types, this is the DNS name of the file system."
  value       = aws_fsx_windows_file_system.this.remote_administration_endpoint
}

output "kms_key_id" {
  description = "The key ID of the KMS key created by this module, or null when a caller-supplied key is used."
  value       = var.create_kms_key ? module.kms_key[0].key_id : null
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used to encrypt the file system and audit logs."
  value       = local.kms_key_arn
}

output "audit_log_group_arn" {
  description = "The ARN of the CloudWatch log group receiving FSx audit logs, or null when audit logging is disabled."
  value       = var.enable_audit_logs ? module.audit_log_group[0].arn : null
}
