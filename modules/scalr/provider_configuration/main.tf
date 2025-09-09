###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = "~> 2.0"
    }
  }
}

###########################
# Data Sources
###########################
data "scalr_current_account" "account" {}

###########################
# Locals
###########################

###########################
# Provider Configurations
###########################

resource "scalr_provider_configuration" "scalr" {
  account_id   = data.scalr_current_account.account.id
  environments = var.scalr_environments
  name         = var.scalr_provider_name
  owners       = var.scalr_owners
  scalr {
    hostname = var.scalr_hostname
    token    = var.scalr_token
  }
}

resource "scalr_provider_configuration" "aws" {
  account_id             = data.scalr_current_account.account.id
  environments           = var.aws_environments
  export_shell_variables = var.aws_export_shell_variables
  name                   = var.aws_provider_name
  owners                 = var.aws_owners
  aws {
    access_key          = var.aws_access_key
    account_type        = var.aws_account_type
    audience            = var.aws_audience
    credentials_type    = var.aws_credentials_type
    external_id         = var.aws_external_id
    role_arn            = var.aws_role_arn
    secret_key          = var.aws_secret_key
    trusted_entity_type = var.aws_trusted_entity_type
  }
}

###########################
# Environment Configurations
###########################

resource "scalr_environment" "this" {
  for_each                        = var.environments
  account_id                      = data.scalr_current_account.account.id
  default_provider_configurations = each.value.default_provider_configurations
  default_workspace_agent_pool_id = each.value.default_workspace_agent_pool_id
  federated_environments          = each.value.federated_environments
  mask_sensitive_output           = var.mask_sensitive_output
  name                            = each.value.name
  remote_backend                  = var.remote_backend
  remote_backend_overridable      = var.remote_backend_overridable
  storage_profile_id              = each.value.storage_profile_id
  tag_ids                         = var.tag_ids
}