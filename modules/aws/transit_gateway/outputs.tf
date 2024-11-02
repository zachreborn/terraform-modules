output "arn" {
  description = "The ARN of the transit gateway"
  value = aws_ec2_transit_gateway.transit_gateway.arn
}

output "association_default_route_table_id" {
  description = "The ID of the default association route table"
  value = aws_ec2_transit_gateway.transit_gateway.association_default_route_table_id
}

output "id" {
  description = "The ID of the transit gateway"
  value = aws_ec2_transit_gateway.transit_gateway.id
}

output "propagation_default_route_table_id" {
  description = "The ID of the default propagation route table"
  value = aws_ec2_transit_gateway.transit_gateway.propagation_default_route_table_id
}

output "transit_gateway_cidr_blocks" {
  description = "The CIDR blocks associated with the transit gateway"
  value = aws_ec2_transit_gateway.transit_gateway.transit_gateway_cidr_blocks
}