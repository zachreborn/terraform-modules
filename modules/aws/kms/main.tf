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
# Locals 
###########################

###########################
# KMS Encryption Key
###########################

resource "aws_kms_key" "this" {
  customer_master_key_spec = var.customer_master_key_spec
  description              = var.description
  deletion_window_in_days  = var.deletion_window_in_days
  enable_key_rotation      = var.enable_key_rotation
  key_usage                = var.key_usage
  is_enabled               = var.is_enabled
  policy                   = var.policy
  tags                     = var.tags
}

resource "aws_kms_alias" "this" {
  name_prefix   = "alias/${var.name_prefix}"
  target_key_id = aws_kms_key.this.key_id
}
