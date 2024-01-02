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

###########################
# Module Configuration
###########################

resource "aws_identitystore_user" "this" {
  for_each = var.users

  display_name       = each.value.display_name
  identity_store_id  = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]
  nickname           = each.value.nickname
  preferred_language = each.value.preferred_language
  timezone           = each.value.timezone
  title              = each.value.title
  user_name          = each.value.user_name
  user_type          = each.value.user_type

  emails {
    value = each.value.email
  }

  name {
    given_name       = each.value.given_name
    honorific_prefix = each.value.honorific_prefix
    honorific_suffix = each.value.honorific_suffix
    middle_name      = each.value.middle_name
    family_name      = each.value.family_name
  }

  phone_numbers {
    value = each.value.phone_number
  }
}
