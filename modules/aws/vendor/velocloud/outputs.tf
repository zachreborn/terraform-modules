output "ec2_instance_id" {
  value = aws_instance.ec2_instance[*].id
}

output "mgmt_eip_id" {
  value = aws_eip.mgmt_external_ip[*].id
}

output "mgmt_eip_ip" {
  value = aws_eip.mgmt_external_ip[*].public_ip
}

output "public_eip_id" {
  value = aws_eip.wan_external_ip[*].id
}

output "public_eip_ip" {
  value = aws_eip.wan_external_ip[*].public_ip
}

output "mgmt_network_interface_id" {
  value = aws_network_interface.mgmt_nic[*].id
}

output "public_network_interface_id" {
  value = aws_network_interface.public_nic[*].id
}

output "private_network_interface_id" {
  value = aws_network_interface.private_nic[*].id
}
