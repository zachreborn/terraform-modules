output "ids" {
  description = "Map of VPC IDs and their transit gateway attachment IDs."
  value = tomap({
    for attachment, value in aws_ec2_transit_gateway_vpc_attachment.this : attachment => value.id
  })
}

# {
#   vpc-12345678 = "tgw-attach-12345678"
# }

output "ids_list" {
  description = "List of transit gateway attachment IDs"
  value       = values(aws_ec2_transit_gateway_vpc_attachment.this)[*].id
}

output "info" {
  description = "A map with information about the transit gateway attachment."
  value = {
    for attachment, values in aws_ec2_transit_gateway_vpc_attachment.this : attachment => {
      appliance_mode_support             = values.appliance_mode_support
      dns_support                        = values.dns_support
      ipv6_support                       = values.ipv6_support
      security_group_referencing_support = values.security_group_referencing_support
      id                                 = values.id
      subnet_ids                         = values.subnet_ids
      transit_gateway_id                 = values.transit_gateway_id
      vpc_owner_id                       = values.vpc_owner_id
    }
  }
}

output "vpc_owner_id" {
  description = "Map of VPC IDs and their owner IDs"
  value       = { for attachment, value in aws_ec2_transit_gateway_vpc_attachment.this : value.vpc_id => value.vpc_owner_id }
}
