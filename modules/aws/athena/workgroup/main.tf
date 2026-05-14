##############################
# Provider Configuration
##############################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

##############################
# Athena Workgroup
##############################

resource "aws_athena_workgroup" "this" {
  name          = var.name
  description   = var.description
  state         = var.state
  force_destroy = var.force_destroy
  tags          = var.tags

  configuration {
    bytes_scanned_cutoff_per_query          = var.bytes_scanned_cutoff_per_query
    enable_minimum_encryption_configuration = var.enable_minimum_encryption_configuration
    enforce_workgroup_configuration         = var.enforce_workgroup_configuration
    execution_role                          = var.execution_role
    publish_cloudwatch_metrics_enabled      = var.publish_cloudwatch_metrics_enabled
    requester_pays_enabled                  = var.requester_pays_enabled

    dynamic "engine_version" {
      for_each = var.selected_engine_version != null ? [1] : []
      content {
        selected_engine_version = var.selected_engine_version
      }
    }

    result_configuration {
      expected_bucket_owner = var.expected_bucket_owner
      output_location       = var.output_location

      dynamic "acl_configuration" {
        for_each = var.s3_acl_option != null ? [1] : []
        content {
          s3_acl_option = var.s3_acl_option
        }
      }

      dynamic "encryption_configuration" {
        for_each = var.encryption_option != null ? [1] : []
        content {
          encryption_option = var.encryption_option
          kms_key_arn       = var.kms_key_arn
        }
      }
    }
  }
}
