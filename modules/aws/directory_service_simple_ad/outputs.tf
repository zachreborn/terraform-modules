output "id" {
  description = "The ID of the directory."
  value       = aws_directory_service_directory.this.id
}

output "dns_ip_addresses" {
  description = "A list of IP addresses of the DNS servers for the directory."
  value       = aws_directory_service_directory.this.dns_ip_addresses
}

output "security_group_id" {
  description = "The ID of the security group created by the directory."
  value       = aws_directory_service_directory.this.security_group_id
}
