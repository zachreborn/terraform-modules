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

data "aws_ssoadmin_instances" "this" {}

###########################
# Locals
###########################

locals {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
}

###########################
# Module Configuration
###########################

resource "aws_identitystore_group" "this" {
  for_each          = var.groups
  description       = each.value.description
  display_name      = each.value.display_name
  identity_store_id = local.identity_store_id
}
