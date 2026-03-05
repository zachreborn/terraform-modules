###########################
# Redshift Cluster Outputs
###########################

output "cluster_identifier" {
  description = "The Cluster Identifier"
  value       = aws_redshift_cluster.this.cluster_identifier
}

output "arn" {
  description = "Amazon Resource Name (ARN) of the cluster"
  value       = aws_redshift_cluster.this.arn
}

output "id" {
  description = "The Redshift Cluster ID"
  value       = aws_redshift_cluster.this.id
}

output "cluster_type" {
  description = "The cluster type"
  value       = aws_redshift_cluster.this.cluster_type
}

output "node_type" {
  description = "The type of nodes in the cluster"
  value       = aws_redshift_cluster.this.node_type
}

output "number_of_nodes" {
  description = "The number of compute nodes in the cluster"
  value       = aws_redshift_cluster.this.number_of_nodes
}

output "database_name" {
  description = "The name of the default database in the cluster"
  value       = aws_redshift_cluster.this.database_name
}

output "master_username" {
  description = "Username for the master DB user"
  value       = aws_redshift_cluster.this.master_username
  sensitive   = true
}

output "endpoint" {
  description = "The connection endpoint"
  value       = aws_redshift_cluster.this.endpoint
}

output "port" {
  description = "The port the cluster responds on"
  value       = aws_redshift_cluster.this.port
}

output "vpc_security_group_ids" {
  description = "The VPC security group IDs associated with the cluster"
  value       = aws_redshift_cluster.this.vpc_security_group_ids
}

output "cluster_subnet_group_name" {
  description = "The name of the cluster subnet group associated with the cluster"
  value       = aws_redshift_cluster.this.cluster_subnet_group_name
}

output "cluster_parameter_group_name" {
  description = "The name of the cluster parameter group associated with the cluster"
  value       = aws_redshift_cluster.this.cluster_parameter_group_name
}

output "availability_zone" {
  description = "The AZ of the cluster"
  value       = aws_redshift_cluster.this.availability_zone
}

output "encrypted" {
  description = "Whether the cluster data is encrypted"
  value       = aws_redshift_cluster.this.encrypted
}

output "kms_key_id" {
  description = "The KMS key ID for encryption"
  value       = aws_redshift_cluster.this.kms_key_id
}

output "enhanced_vpc_routing" {
  description = "Whether enhanced VPC routing is enabled"
  value       = aws_redshift_cluster.this.enhanced_vpc_routing
}

output "publicly_accessible" {
  description = "Whether the cluster is publicly accessible"
  value       = aws_redshift_cluster.this.publicly_accessible
}

output "preferred_maintenance_window" {
  description = "The maintenance window"
  value       = aws_redshift_cluster.this.preferred_maintenance_window
}

output "automated_snapshot_retention_period" {
  description = "The number of days automated snapshots are retained"
  value       = aws_redshift_cluster.this.automated_snapshot_retention_period
}

output "cluster_version" {
  description = "The version of Redshift engine software"
  value       = aws_redshift_cluster.this.cluster_version
}

output "allow_version_upgrade" {
  description = "Whether major version upgrades can be applied"
  value       = aws_redshift_cluster.this.allow_version_upgrade
}

output "cluster_namespace_arn" {
  description = "The namespace Amazon Resource Name (ARN) of the cluster"
  value       = aws_redshift_cluster.this.cluster_namespace_arn
}

output "cluster_public_key" {
  description = "The public key for the cluster"
  value       = aws_redshift_cluster.this.cluster_public_key
}

output "cluster_revision_number" {
  description = "The specific revision number of the database in the cluster"
  value       = aws_redshift_cluster.this.cluster_revision_number
}

output "dns_name" {
  description = "The DNS name of the cluster"
  value       = aws_redshift_cluster.this.dns_name
}

###########################
# Subnet Group Outputs
###########################

output "subnet_group_id" {
  description = "The Redshift Subnet group ID"
  value       = try(aws_redshift_subnet_group.this[0].id, null)
}

output "subnet_group_arn" {
  description = "Amazon Resource Name (ARN) of the Redshift Subnet group"
  value       = try(aws_redshift_subnet_group.this[0].arn, null)
}

###########################
# Parameter Group Outputs
###########################

output "parameter_group_id" {
  description = "The Redshift parameter group ID"
  value       = try(aws_redshift_parameter_group.this[0].id, null)
}

output "parameter_group_arn" {
  description = "Amazon Resource Name (ARN) of the Redshift parameter group"
  value       = try(aws_redshift_parameter_group.this[0].arn, null)
}

###########################
# Snapshot Schedule Outputs
###########################

output "snapshot_schedule_id" {
  description = "The Redshift snapshot schedule ID"
  value       = try(aws_redshift_snapshot_schedule.this[0].id, null)
}

output "snapshot_schedule_arn" {
  description = "Amazon Resource Name (ARN) of the Redshift snapshot schedule"
  value       = try(aws_redshift_snapshot_schedule.this[0].arn, null)
}