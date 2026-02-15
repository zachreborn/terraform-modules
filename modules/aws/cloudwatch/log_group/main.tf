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

resource "aws_cloudwatch_log_group" "this" {
  kms_key_id        = var.kms_key_id
  log_group_class   = var.log_group_class
  name_prefix       = var.name_prefix
  retention_in_days = var.retention_in_days
  skip_destroy      = var.skip_destroy
  tags              = var.tags
}