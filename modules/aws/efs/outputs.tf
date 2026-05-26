output "arn" {
  description = "The ARN of the file system."
  value       = aws_efs_file_system.this.arn
}

output "dns_name" {
  description = "The DNS name of the file system."
  value       = aws_efs_file_system.this.dns_name
}

output "id" {
  description = "The ID that identifies the file system (e.g. fs-ccfc0d65)."
  value       = aws_efs_file_system.this.id
}

output "mount_target_dns_names" {
  description = "Map of subnet ID to DNS name for each EFS mount target."
  value = {
    for subnet_id, mount_target in aws_efs_mount_target.this : subnet_id => mount_target.dns_name
  }
}

output "mount_target_ip_addresses" {
  description = "Map of subnet ID to IP address for each EFS mount target."
  value = {
    for subnet_id, mount_target in aws_efs_mount_target.this : subnet_id => mount_target.ip_address
  }
}

output "number_of_mount_targets" {
  description = "The current number of mount targets that the file system has."
  value       = aws_efs_file_system.this.number_of_mount_targets
}

output "size_in_bytes" {
  description = "The latest known metered size (in bytes) of data stored in the file system."
  value       = aws_efs_file_system.this.size_in_bytes
}
