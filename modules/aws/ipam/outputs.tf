###########################
# Resource Outputs
###########################

output "ipam_id" {
  description = "The ID of the IPAM."
  value       = aws_vpc_ipam.this.id
}

output "ipam_arn" {
  description = "The ARN of the IPAM."
  value       = aws_vpc_ipam.this.arn
}

output "public_scope_id" {
  description = "The ID of the IPAM's default public scope."
  value       = aws_vpc_ipam.this.public_default_scope_id
}

output "private_scope_id" {
  description = "The ID of the IPAM's default private scope."
  value       = aws_vpc_ipam.this.private_default_scope_id
}

output "scope_ids" {
  description = "Map of additional private scope keys to their scope IDs."
  value       = { for key, scope in aws_vpc_ipam_scope.additional : key => scope.id }
}

output "pool_ids" {
  description = "Map of pool key to pool ID across all hierarchy levels."
  value       = { for key, pool in local.all_pools : key => pool.id }
}

output "pool_arns" {
  description = "Map of pool key to pool ARN across all hierarchy levels."
  value       = { for key, pool in local.all_pools : key => pool.arn }
}

output "pool_cidrs" {
  description = "Map of pool key to the list of CIDR(s) provisioned into that pool."
  value = {
    for pool_key in keys(var.pools) : pool_key => [
      for cidr_key, cidr in local.pool_provisioned_cidrs :
      aws_vpc_ipam_pool_cidr.this[cidr_key].cidr if cidr.pool_key == pool_key
    ]
  }
}

output "allocation_cidrs" {
  description = "Map of allocation key to the allocated CIDR block, suitable for feeding into the VPC module."
  value       = { for key, allocation in aws_vpc_ipam_pool_cidr_allocation.this : key => allocation.cidr }
}

output "ram_share_arns" {
  description = "Map of RAM share key to the RAM resource-share ARN (populated when sharing is enabled)."
  value       = { for key, share in module.ram : key => share.arn }
}
