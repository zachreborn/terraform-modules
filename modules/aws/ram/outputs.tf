###########################
# Resource Outputs
###########################

output "arn" {
  description = "The ARN of the resource share."
  value       = aws_ram_resource_share.this.arn
}

output "id" {
  description = "The ID of the resource share."
  value       = aws_ram_resource_share.this.id
}

output "resource_association_ids" {
  description = "A map of resource ARN to the ID of the aws_ram_resource_association created for it."
  value       = { for k, v in aws_ram_resource_association.this : k => v.id }
}
