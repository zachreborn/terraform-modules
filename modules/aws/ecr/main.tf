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

resource "aws_ecr_repository" "this" {
  force_delete         = var.force_delete
  image_tag_mutability = var.image_tag_mutability
  name                 = var.name
  tags                 = var.tags

  dynamic "encryption_configuration" {
    for_each = var.enable_encryption != null ? [1] : []

    content {
      encryption_type = var.encryption_type
      kms_key         = var.kms_key
    }
  }

  dynamic "image_tag_mutability_exclusion_filter" {
    for_each = var.image_tag_mutability_exclusion_filter != null ? var.image_tag_mutability_exclusion_filter : []

    content {
      filter      = image_tag_mutability_exclusion_filter.value
      filter_type = "WILDCARD"
    }
  }
}
