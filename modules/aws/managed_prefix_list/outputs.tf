###########################
# Managed Prefix List Outputs
###########################

output "arn" {
  description = "ARN of the managed prefix list."
  value       = aws_ec2_managed_prefix_list.this.arn
}

output "id" {
  description = "ID of the managed prefix list. Use this value to reference the prefix list in security groups, route tables, and other resources."
  value       = aws_ec2_managed_prefix_list.this.id
}

output "owner_id" {
  description = "ID of the AWS account that owns this prefix list."
  value       = aws_ec2_managed_prefix_list.this.owner_id
}

output "version" {
  description = "Latest version of this prefix list."
  value       = aws_ec2_managed_prefix_list.this.version
}
