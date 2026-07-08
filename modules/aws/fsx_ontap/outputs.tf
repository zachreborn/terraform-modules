###########################
# Resource Outputs
###########################

output "id" {
  description = "The identifier of the FSx for NetApp ONTAP file system."
  value       = aws_fsx_ontap_file_system.this.id
}

output "arn" {
  description = "The Amazon Resource Name (ARN) of the file system."
  value       = aws_fsx_ontap_file_system.this.arn
}

output "dns_name" {
  description = "The DNS name for the file system."
  value       = aws_fsx_ontap_file_system.this.dns_name
}

output "endpoints" {
  description = "The management and intercluster endpoints (DNS names and IP addresses) used to access and replicate the file system."
  value       = aws_fsx_ontap_file_system.this.endpoints
}

output "network_interface_ids" {
  description = "The set of Elastic Network Interface IDs from which the file system is accessible."
  value       = aws_fsx_ontap_file_system.this.network_interface_ids
}

output "owner_id" {
  description = "The AWS account identifier that owns the file system."
  value       = aws_fsx_ontap_file_system.this.owner_id
}

output "vpc_id" {
  description = "The identifier of the Virtual Private Cloud for the file system."
  value       = aws_fsx_ontap_file_system.this.vpc_id
}

output "kms_key_id" {
  description = "The key ID of the KMS key created by this module, or null when a caller-supplied key is used."
  value       = var.create_kms_key ? module.kms_key[0].key_id : null
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used to encrypt the file system."
  value       = local.kms_key_arn
}

output "storage_virtual_machine_ids" {
  description = "Map of Storage Virtual Machine logical names to their IDs."
  value       = { for key, svm in aws_fsx_ontap_storage_virtual_machine.this : key => svm.id }
}

output "storage_virtual_machine_arns" {
  description = "Map of Storage Virtual Machine logical names to their ARNs."
  value       = { for key, svm in aws_fsx_ontap_storage_virtual_machine.this : key => svm.arn }
}

output "storage_virtual_machine_endpoints" {
  description = "Map of Storage Virtual Machine logical names to their endpoints (iSCSI, management, NFS, and SMB DNS names and IP addresses)."
  value       = { for key, svm in aws_fsx_ontap_storage_virtual_machine.this : key => svm.endpoints }
}

output "storage_virtual_machine_uuids" {
  description = "Map of Storage Virtual Machine logical names to their UUIDs."
  value       = { for key, svm in aws_fsx_ontap_storage_virtual_machine.this : key => svm.uuid }
}

output "volume_ids" {
  description = "Map of volume logical names to their IDs."
  value       = { for key, vol in aws_fsx_ontap_volume.this : key => vol.id }
}

output "volume_arns" {
  description = "Map of volume logical names to their ARNs."
  value       = { for key, vol in aws_fsx_ontap_volume.this : key => vol.arn }
}

output "volume_uuids" {
  description = "Map of volume logical names to their UUIDs."
  value       = { for key, vol in aws_fsx_ontap_volume.this : key => vol.uuid }
}
