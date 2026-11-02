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
# Launch Template Outputs
###########################

output "launch_template_id" {
  description = "ID of the ZPA App Connector launch template."
  value       = aws_launch_template.zpa.id
}

output "launch_template_arn" {
  description = "ARN of the ZPA App Connector launch template."
  value       = aws_launch_template.zpa.arn
}

output "launch_template_latest_version" {
  description = "Latest version number of the launch template."
  value       = aws_launch_template.zpa.latest_version
}

output "ami_id" {
  description = "AMI ID used by the launch template (resolved Marketplace el9 or override)."
  value       = local.ami_id
}

###########################
# Auto Scaling Group Outputs
###########################

output "asg_name" {
  description = "Name of the ZPA App Connector Auto Scaling group."
  value       = aws_autoscaling_group.zpa.name
}

output "asg_arn" {
  description = "ARN of the ZPA App Connector Auto Scaling group."
  value       = aws_autoscaling_group.zpa.arn
}

output "asg_min_size" {
  description = "Minimum size of the Auto Scaling group."
  value       = aws_autoscaling_group.zpa.min_size
}

output "asg_max_size" {
  description = "Maximum size of the Auto Scaling group."
  value       = aws_autoscaling_group.zpa.max_size
}

output "asg_desired_capacity" {
  description = "Desired capacity of the Auto Scaling group."
  value       = aws_autoscaling_group.zpa.desired_capacity
}
