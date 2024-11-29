output "ids" {
  description = "Map of VPC IDs and their transit gateway attachment IDs."
  value       = { for attachment, value in aws_ec2_transit_gateway_vpc_attachment.this : value.vpc_id => value.id }
}

output "ids_list" {
  description = "List of transit gateway attachment IDs"
  value       = values(aws_ec2_transit_gateway_vpc_attachment.this)[*].id
}

output "vpc_owner_id" {
  description = "Map of VPC IDs and their owner IDs"
  value       = { for attachment, value in aws_ec2_transit_gateway_vpc_attachment.this : value.vpc_id => value.vpc_owner_id }
}
