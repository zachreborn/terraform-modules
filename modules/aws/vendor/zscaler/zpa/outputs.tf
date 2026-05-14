###########################
# Security Group Outputs
###########################

output "security_group_id" {
  description = "ID of the ZPA App Connector security group."
  value       = aws_security_group.zpa.id
}

output "security_group_arn" {
  description = "ARN of the ZPA App Connector security group."
  value       = aws_security_group.zpa.arn
}

###########################
# EC2 Instance Outputs
###########################

output "arns" {
  description = "List of ARNs for the ZPA App Connector EC2 instances."
  value       = aws_instance.zpa[*].arn
}

output "instance_ids" {
  description = "List of EC2 instance IDs for the ZPA App Connector instances."
  value       = aws_instance.zpa[*].id
}

output "private_ips" {
  description = "List of private IP addresses assigned to the ZPA App Connector instances."
  value       = aws_instance.zpa[*].private_ip
}
