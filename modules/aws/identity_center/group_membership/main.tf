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

resource "aws_identitystore_group_membership" "this" {
  for_each          = {for user_name, user_id in var.users : user_name => user_id}
  identity_store_id = local.identity_store_id
  group_id          = var.group_id
  member_id         = each.value
}
