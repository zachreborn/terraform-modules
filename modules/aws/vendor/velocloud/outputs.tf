output "ec2_instance_id" {
  description = "The EC2 instance IDs as a list"
  value       = aws_instance.ec2_instance[*].id
}

output "public_eip_id" {
  description = "The EIP IDs as a list"
  value       = aws_eip.wan_external_ip[*].id
}

output "public_eip_ip" {
  description = "The EIP public IPs as a list"
  value       = aws_eip.wan_external_ip[*].public_ip
}

output "mgmt_network_interface_id" {
  description = "The mgmt network interface IDs as a list"
  value       = aws_network_interface.mgmt_nic[*].id
}

output "mgmt_network_interface_private_ips" {
  description = "The mgmt network interface private IPs as a list"
  value       = aws_network_interface.mgmt_nic[*].private_ips
}

output "public_network_interface_id" {
  description = "The public network interface IDs as a list"
  value       = aws_network_interface.public_nic[*].id
}

output "public_network_interface_private_ips" {
  description = "The public network interface private IPs as a list"
  value       = aws_network_interface.public_nic[*].private_ips
}

output "private_network_interface_id" {
  description = "The private network interface IDs as a list"
  value       = aws_network_interface.private_nic[*].id
}

output "private_network_interface_private_ips" {
  description = "The private network interface private IPs as a list"
  value       = aws_network_interface.private_nic[*].private_ips
}