output "arn" {
  description = "The ARN of the transit gateway connect peer"
  value       = aws_ec2_transit_gateway_connect_peer.peer.arn
}

output "bgp_asn" {
  description = "The BGP ASN of the connect peer."
  value       = aws_ec2_transit_gateway_connect_peer.peer.bgp_asn
}

output "bgp_peer_address" {
  description = "The BGP peer address within the connect tunnel. This is the address peering with the transit gateway."
  value       = aws_ec2_transit_gateway_connect_peer.peer.bgp_peer_address
}

output "bgp_transit_gateway_addresses" {
  description = "The BGP transit gateway address within the connect tunnel. This is the address of the transit gateway."
  value       = aws_ec2_transit_gateway_connect_peer.peer.bgp_transit_gateway_address
}

output "id" {
  description = "The ID of the Transit Gateway Connect Peer"
  value       = aws_ec2_transit_gateway_connect_peer.peer.id
}

output "inside_cidr_blocks" {
  description = "The CIDR blocks associated with the inside IP addresses of the connect peer."
  value       = aws_ec2_transit_gateway_connect_peer.peer.inside_cidr_blocks
}

output "peer_address" {
  description = "The IP address of the connect peer."
  value       = aws_ec2_transit_gateway_connect_peer.peer.peer_address
}

output "transit_gateway_address" {
  description = "The IP address of the transit gateway. This is the IP used to connect to the transit gateway."
  value       = aws_ec2_transit_gateway_connect_peer.peer.transit_gateway_address
}