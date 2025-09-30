###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Locals
###########################

locals {
  enable_logging = var.logging_bucket_name != null
}

###########################
# Redshift Cluster
###########################

resource "aws_redshift_cluster" "this" {
  # Required parameters
  cluster_identifier = var.cluster_identifier
  node_type          = var.node_type

  # Database configuration
  database_name          = var.database_name
  master_username        = var.master_username
  master_password        = var.master_password
  manage_master_password = var.manage_master_password
  master_password_secret_kms_key_id = var.master_password_secret_kms_key_id

  # Cluster configuration
  cluster_type             = var.cluster_type
  number_of_nodes          = var.cluster_type == "multi-node" ? var.number_of_nodes : null
  cluster_version          = var.cluster_version
  cluster_parameter_group_name = var.cluster_parameter_group_name
  cluster_subnet_group_name    = var.cluster_subnet_group_name

  # Security
  vpc_security_group_ids       = var.vpc_security_group_ids
  iam_roles                    = var.iam_roles
  kms_key_id                   = var.kms_key_id
  encrypted                    = var.encrypted
  enhanced_vpc_routing         = var.enhanced_vpc_routing

  # Networking
  availability_zone              = var.availability_zone
  availability_zone_relocation_enabled = var.availability_zone_relocation_enabled
  publicly_accessible            = var.publicly_accessible
  elastic_ip                     = var.elastic_ip
  port                           = var.port

  # Maintenance and updates
  preferred_maintenance_window = var.preferred_maintenance_window
  automated_snapshot_retention_period = var.automated_snapshot_retention_period
  manual_snapshot_retention_period    = var.manual_snapshot_retention_period
  final_snapshot_identifier   = var.final_snapshot_identifier
  skip_final_snapshot         = var.skip_final_snapshot
  snapshot_cluster_identifier = var.snapshot_cluster_identifier
  snapshot_identifier         = var.snapshot_identifier

  # Backup and recovery
  allow_version_upgrade = var.allow_version_upgrade
  apply_immediately     = var.apply_immediately

  # Monitoring and logging
  dynamic "logging_properties" {
    for_each = local.enable_logging ? [1] : []
    content {
      bucket_name          = var.logging_bucket_name
      s3_key_prefix        = var.logging_s3_key_prefix
      log_destination_type = var.log_destination_type
      log_exports          = var.log_exports
    }
  }

  # Aqua configuration
  aqua_configuration_status = var.aqua_configuration_status

  # Multi-AZ configuration
  multi_az = var.multi_az

  # Default IAM role
  default_iam_role_arn = var.default_iam_role_arn

  # Maintenance track
  maintenance_track_name = var.maintenance_track_name

  tags = var.tags

  lifecycle {
    ignore_changes = [
      master_password
    ]
  }
}

###########################
# Redshift Subnet Group
###########################

resource "aws_redshift_subnet_group" "this" {
  count = var.create_subnet_group ? 1 : 0

  name        = var.subnet_group_name
  description = var.subnet_group_description
  subnet_ids  = var.subnet_ids
  tags        = var.tags
}

###########################
# Redshift Parameter Group
###########################

resource "aws_redshift_parameter_group" "this" {
  count = var.create_parameter_group ? 1 : 0

  name        = var.parameter_group_name
  family      = var.parameter_group_family
  description = var.parameter_group_description

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = var.tags
}

###########################
# Redshift Cluster IAM Roles Association
###########################

resource "aws_redshift_cluster_iam_roles" "this" {
  count = var.manage_iam_roles && length(var.iam_roles) > 0 ? 1 : 0

  cluster_identifier   = aws_redshift_cluster.this.cluster_identifier
  iam_role_arns        = var.iam_roles
  default_iam_role_arn = var.default_iam_role_arn
}

###########################
# Redshift Snapshot Schedule
###########################

resource "aws_redshift_snapshot_schedule" "this" {
  count = var.create_snapshot_schedule ? 1 : 0

  identifier  = var.snapshot_schedule_identifier
  description = var.snapshot_schedule_description
  definitions = var.snapshot_schedule_definitions
  tags        = var.tags
}

resource "aws_redshift_snapshot_schedule_association" "this" {
  count = var.create_snapshot_schedule ? 1 : 0

  cluster_identifier  = aws_redshift_cluster.this.cluster_identifier
  schedule_identifier = aws_redshift_snapshot_schedule.this[0].id
}

###########################
# Redshift Usage Limit
###########################

resource "aws_redshift_usage_limit" "this" {
  for_each = var.usage_limits

  cluster_identifier = aws_redshift_cluster.this.cluster_identifier
  feature_type       = each.value.feature_type
  limit_type         = each.value.limit_type
  amount             = each.value.amount
  breach_action      = each.value.breach_action
  period             = each.value.period
  tags               = var.tags
}