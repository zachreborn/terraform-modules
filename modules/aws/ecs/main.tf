###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

###########################
# Data Sources
###########################


###########################
# Locals
###########################

###########################
# Module Configuration
###########################

# KMS Key for container storage encryption
module "container_storage_key" {
  source = "../kms"

  description = "ECS Cluster Key"
  name        = "ecs-cluster-key-${var.cluster_name}"
}

# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
  tags = var.tags

  dynamic "configuration" {
    for_each = var.configuration

    content {
      dynamic "execute_command_configuration" {
        for_each = configuration.value.execute_command_configuration

        content {
          kms_key_id = execute_command_configuration.value.kms_key_id
          logging    = execute_command_configuration.value.logging

          dynamic "log_configuration" {
            for_each = execute_command_configuration.value.log_configuration

            content {
              cloud_watch_encryption_enabled = log_configuration.value.cloud_watch_encryption_enabled
              cloud_watch_log_group_name     = log_configuration.value.cloud_watch_log_group_name
              s3_bucket_name                 = log_configuration.value.s3_bucket_name
              s3_bucket_encryption_enabled   = log_configuration.value.s3_bucket_encryption_enabled
              s3_key_prefix                  = log_configuration.value.s3_key_prefix
            }
          }
        }
      }

      dynamic "managed_storage_configuration" {
        for_each = configuration.value.managed_storage_configuration

        content {
          fargate_ephemeral_storage_kms_key_id = managed_storage_configuration.value.fargate_ephemeral_storage_kms_key_id
          kms_key_id                           = managed_storage_configuration.value.kms_key_id
        }
      }
    }
  }

  dynamic "service_connect_defaults" {
    for_each = var.service_connect_default_namespace ? [1] : []

    content {
      namespace = service_connect_default_namespace.value
    }
  }

  dynamic "setting" {
    for_each = var.container_insights ? [1] : []

    content {
      name  = "containerInsights"
      value = setting.value
    }
  }
}
