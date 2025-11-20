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
