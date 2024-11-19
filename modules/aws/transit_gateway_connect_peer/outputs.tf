output "arns" {
  description = "A map of ARNs of the transit gateway connect peers."
  value       = { for key, value in aws_ec2_transit_gateway_connect_peer.peer : key => value.arn }
}

output "bgp_asns" {
  description = "A map of BGP ASNs of the connect peers."
  value       = { for key, value in aws_ec2_transit_gateway_connect_peer.peer : key => value.bgp_asn }
}

output "bgp_peer_addresses" {
  description = "A map of BGP peer address within the connect tunnels. This is the address peering with the transit gateway."
  value       = { for key, value in aws_ec2_transit_gateway_connect_peer.peer : key => value.peer_address }
}

output "bgp_transit_gateway_addresses" {
  description = "A map of the BGP transit gateway addresses within the connect tunnel. This is the address of the transit gateway."
  value       = { for key, value in aws_ec2_transit_gateway_connect_peer.peer : key => value.transit_gateway_address }
}

output "ids" {
  description = "A map of the IDs of the Transit Gateway Connect Peers"
  value       = { for key, value in aws_ec2_transit_gateway_connect_peer.peer : key => value.id }
}

output "inside_cidr_blocks" {
  description = "The CIDR blocks associated with the inside IP addresses of the connect peer."
  value       = { for key, value in aws_ec2_transit_gateway_connect_peer.peer : key => value.inside_cidr_blocks }
}

output "peer_addresses" {
  description = "A map of the IP address of the connect peers."
  value       = { for key, value in aws_ec2_transit_gateway_connect_peer.peer : key => value.peer_address }
}

output "transit_gateway_addresses" {
  description = "A map of IP address of the transit gateway. This is the IP used to connect to the transit gateway."
  value       = { for key, value in aws_ec2_transit_gateway_connect_peer.peer : key => value.transit_gateway_address }
}