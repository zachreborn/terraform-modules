output "routes" {
  description = "Map of routes and their next hops"
  value       = { for route in aws_ec2_transit_gateway_route.route : route.destination_cidr_block => route.transit_gateway_attachment_id }
}
