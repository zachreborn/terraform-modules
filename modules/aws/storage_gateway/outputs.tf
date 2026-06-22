###########################
# Resource Outputs
###########################

output "gateway_id" {
  description = "The identifier of the Storage Gateway."
  value       = aws_storagegateway_gateway.this.gateway_id
}

output "gateway_arn" {
  description = "The Amazon Resource Name (ARN) of the Storage Gateway."
  value       = aws_storagegateway_gateway.this.arn
}

output "ec2_instance_id" {
  description = "The ID of the EC2 instance backing the gateway, when the gateway runs on EC2."
  value       = aws_storagegateway_gateway.this.ec2_instance_id
}

output "gateway_network_interface" {
  description = "The network interfaces of the gateway."
  value       = aws_storagegateway_gateway.this.gateway_network_interface
}

output "host_environment" {
  description = "The type of hypervisor environment used by the gateway host."
  value       = aws_storagegateway_gateway.this.host_environment
}

output "cache_disk_ids" {
  description = "The set of local disk IDs allocated as cache storage on the gateway."
  value       = [for cache in aws_storagegateway_cache.this : cache.disk_id]
}

output "file_system_association_arns" {
  description = "Map of file system association logical names to their ARNs."
  value       = { for key, association in aws_storagegateway_file_system_association.this : key => association.arn }
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the CloudWatch log group used for gateway health logs, or null when none is created or supplied."
  value       = local.cloudwatch_log_group_arn
}

output "kms_key_id" {
  description = "The key ID of the KMS key created by this module, or null when none is created."
  value       = var.create_cloudwatch_log_group && var.create_kms_key ? module.kms_key[0].key_id : null
}

output "kms_key_arn" {
  description = "The ARN of the KMS key used to encrypt the gateway log group, or null when none is used."
  value       = local.kms_key_arn
}
