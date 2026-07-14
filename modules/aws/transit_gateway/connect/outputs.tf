##################################
# Transit Gateway Connect Outputs
##################################
output "attachment_id" {
  description = "The ID of the transit gateway connect attachment."
  value       = aws_ec2_transit_gateway_connect.connect_attachment.id
}

##################################
# Transit Gateway Connect Peer Outputs
##################################
output "arns" {
  description = "A map of ARNs of the transit gateway connect peers."
  value       = { for key, value in aws_ec2_transit_gateway_connect_peer.peer : key => value.arn }
}

output "bgp_asns" {
  description = "A map of BGP ASNs of the connect peers."
  value       = { for key, value in aws_ec2_transit_gateway_connect_peer.peer : key => value.bgp_asn }
}

output "ids" {
  description = "A map of the IDs of the transit gateway connect peers"
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

# Complex Outputs
output "configurations" {
  description = "A map of the transit gateway connect peer configurations."
  value = { for key, value in aws_ec2_transit_gateway_connect_peer.peer : key => {
    bgp_asn                 = value.bgp_asn
    id                      = value.id
    insider_cidr_blocks     = value.inside_cidr_blocks
    peer_address            = value.peer_address
    transit_gateway_address = value.transit_gateway_address
    }
  }
}