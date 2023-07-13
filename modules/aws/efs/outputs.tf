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
  description = "List of DNS names for the EFS File System."
  value = {
    for mount_target in aws_efs_mount_target.this : mount_target.id => mount_target.dns_name
  }
}
