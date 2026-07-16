output "private_subnet_ids" {
  value = aws_subnet.private_subnets[*].id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets[*].id
}

output "db_subnet_ids" {
  value = aws_subnet.db_subnets[*].id
}

output "dmz_subnet_ids" {
  value = aws_subnet.dmz_subnets[*].id
}

output "mgmt_subnet_ids" {
  value = aws_subnet.mgmt_subnets[*].id
}

output "private_subnets" {
  value = aws_subnet.private_subnets[*].cidr_block
}

output "public_subnets" {
  value = aws_subnet.public_subnets[*].cidr_block
}

output "workspaces_subnet_ids" {
  value = aws_subnet.workspaces_subnets[*].id
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.vpc.cidr_block
}

output "vpc_ipv6_cidr_block" {
  description = "The IPv6 CIDR block assigned to the VPC. Null when enable_ipv6 is false."
  value       = aws_vpc.vpc.ipv6_cidr_block
}

output "vpc_ipv6_association_id" {
  description = "The association ID for the VPC's IPv6 CIDR block. Null when enable_ipv6 is false."
  value       = aws_vpc.vpc.ipv6_association_id
}

output "dhcp_options_id" {
  description = "The ID of the DHCP options set associated with the VPC."
  value       = aws_vpc.vpc.dhcp_options_id
}

output "main_route_table_id" {
  description = "The ID of the main route table associated with the VPC."
  value       = aws_vpc.vpc.main_route_table_id
}

output "default_route_table_id" {
  description = "The ID of the route table created by default on VPC creation."
  value       = aws_vpc.vpc.default_route_table_id
}

output "default_network_acl_id" {
  description = "The ID of the network ACL created by default on VPC creation."
  value       = aws_vpc.vpc.default_network_acl_id
}

output "owner_id" {
  description = "The ID of the AWS account that owns the VPC."
  value       = aws_vpc.vpc.owner_id
}

output "tags_all" {
  description = "A map of tags assigned to the VPC, including those inherited from the provider default_tags configuration block."
  value       = aws_vpc.vpc.tags_all
}

output "egress_only_internet_gateway_id" {
  description = "The ID of the egress-only internet gateway used for outbound-only IPv6. Null when enable_ipv6 is false."
  value       = one(aws_egress_only_internet_gateway.eigw[*].id)
}

output "vpc_endpoint_security_group_id" {
  description = "The ID of the security group attached to the SSM/ECR/CloudWatch Logs VPC endpoints."
  value       = module.ssm_vpc_endpoint_sg.id
}

output "vpc_endpoint_security_group_name" {
  description = "The name of the security group attached to the SSM/ECR/CloudWatch Logs VPC endpoints."
  value       = module.ssm_vpc_endpoint_sg.name
}

output "custom_vpc_endpoint_ids" {
  description = "Map of caller-defined VPC endpoint (var.vpc_endpoints) names to their resource ids."
  value       = { for k, v in aws_vpc_endpoint.custom : k => v.id }
}

output "public_route_table_ids" {
  value = aws_route_table.public_route_table[*].id
}

output "private_route_table_ids" {
  value = aws_route_table.private_route_table[*].id
}

output "db_route_table_ids" {
  value = aws_route_table.db_route_table[*].id
}

output "dmz_route_table_ids" {
  value = aws_route_table.dmz_route_table[*].id
}

output "mgmt_route_table_ids" {
  value = aws_route_table.mgmt_route_table[*].id
}

output "workspaces_route_table_ids" {
  value = aws_route_table.workspaces_route_table[*].id
}

output "default_security_group_id" {
  value = aws_vpc.vpc[*].default_security_group_id
}

output "nat_eips" {
  value = aws_eip.nateip[*].id
}

output "nat_eips_public_ips" {
  value = aws_eip.nateip[*].public_ip
}

output "natgw_ids" {
  value = aws_nat_gateway.natgw[*].id
}

output "igw_id" {
  value = aws_internet_gateway.igw[*].id
}

output "availability_zone" {
  value = aws_subnet.private_subnets[*].availability_zone
}

output "name" {
  description = "The name of the VPC"
  value       = aws_vpc.vpc.tags["Name"]
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.vpc.arn
}

output "private_subnet_arns" {
  description = "List of ARNs of private subnets"
  value       = aws_subnet.private_subnets[*].arn
}

output "internet_monitor_arn" {
  description = "The ARN of the CloudWatch Internet Monitor. Null when enable_internet_monitor is false."
  value       = one(aws_internetmonitor_monitor.this[*].arn)
}

output "internet_monitor_id" {
  description = "The ID (name) of the CloudWatch Internet Monitor. Null when enable_internet_monitor is false."
  value       = one(aws_internetmonitor_monitor.this[*].id)
}
