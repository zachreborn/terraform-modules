terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

############################
# Locals for readability
############################

locals {
  # Sets specific tags as required by the module and merges them with input tags
  tags = merge(var.tags, {
    environment = var.environment
    Name        = var.name
    terraform   = true
  })
}

############################
# EFS File System
############################

resource "aws_efs_file_system" "this" {
  availability_zone_name          = var.availability_zone_name
  creation_token                  = var.creation_token
  encrypted                       = var.encrypted
  kms_key_id                      = var.kms_key_id
  performance_mode                = var.performance_mode
  provisioned_throughput_in_mibps = var.provisioned_throughput_in_mibps
  throughput_mode                 = var.throughput_mode
  tags                            = local.tags

  dynamic "lifecycle_policy" {
    for_each = var.lifecycle_policy
    content {
      transition_to_ia                    = lifecycle_policy.value.transition_to_ia
      transition_to_primary_storage_class = lifecycle_policy.value.transition_to_primary_storage_class
      transition_to_archive               = lifecycle_policy.value.transition_to_archive
    }
  }

  lifecycle {
    precondition {
      condition     = var.kms_key_id == null || var.encrypted == true
      error_message = "kms_key_id can only be set when encrypted is true."
    }
    precondition {
      condition     = var.throughput_mode != "provisioned" || var.provisioned_throughput_in_mibps != null
      error_message = "provisioned_throughput_in_mibps must be set when throughput_mode is 'provisioned'."
    }
    precondition {
      condition     = var.throughput_mode == "provisioned" || var.provisioned_throughput_in_mibps == null
      error_message = "provisioned_throughput_in_mibps must only be set when throughput_mode is 'provisioned'."
    }
  }
}

resource "aws_efs_mount_target" "this" {
  for_each        = toset(var.subnet_ids)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.key
  security_groups = var.security_groups
}

