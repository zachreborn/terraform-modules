###########################
# Provider Configuration
###########################
terraform {
  # >= 1.4.0: terraform_data (used below to carry the create_kms_key /
  # kms_key_arn mutual-exclusivity precondition) was introduced in Terraform 1.4
  # / OpenTofu 1.6. The templates map also uses optional() object attributes,
  # which require 1.3.0 or newer.
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Locals
###########################

locals {
  # Whether the staging area should be encrypted with a customer managed key,
  # either one this module creates or one the caller supplied. This is derived
  # from known-at-plan-time booleans rather than from the key ARN itself, so the
  # resolved ebs_encryption value never becomes unknown during a plan.
  kms_key_enabled = var.create_kms_key || var.kms_key_arn != null

  kms_key_arn = var.create_kms_key ? module.kms_key[0].arn : var.kms_key_arn

  # Inject the resolved customer managed key into every template that did not
  # set one explicitly, and keep ebs_encryption consistent with it.
  templates = {
    for key, template in var.templates : key => merge(template, {
      ebs_encryption = (
        template.ebs_encryption != null
        ? template.ebs_encryption
        : (local.kms_key_enabled ? "CUSTOM" : "DEFAULT")
      )

      ebs_encryption_key_arn = (
        template.ebs_encryption_key_arn != null
        ? template.ebs_encryption_key_arn
        : local.kms_key_arn
      )

      region = template.region != null ? template.region : var.region
    })
  }
}

###########################
# Input Validation
###########################

# This module declares no aws_* resources of its own, so there is nothing to
# attach a lifecycle precondition to directly. Terraform's variable `validation`
# blocks cannot cross-reference another variable until Terraform 1.9, so this
# built-in, provider-less resource exists solely to carry the precondition that
# enforces `create_kms_key` / `kms_key_arn` mutual exclusivity.
resource "terraform_data" "validate_kms_inputs" {
  lifecycle {
    precondition {
      condition     = !(var.create_kms_key && var.kms_key_arn != null)
      error_message = "create_kms_key and kms_key_arn are mutually exclusive. Set create_kms_key to false when supplying an existing kms_key_arn."
    }
  }
}

###########################
# Staging Area KMS Key (composition)
###########################

module "kms_key" {
  count  = var.create_kms_key ? 1 : 0
  source = "../kms"

  name_prefix             = var.kms_key_name_prefix
  description             = var.kms_key_description
  deletion_window_in_days = var.kms_key_deletion_window_in_days
  enable_key_rotation     = var.kms_key_enable_key_rotation
  policy                  = var.kms_key_policy
  region                  = var.region
  tags                    = merge(tomap({ Name = var.kms_key_name_prefix }), var.tags)
}

###########################
# Service Initialization (composition)
###########################

module "initialization" {
  count  = var.create_initialization ? 1 : 0
  source = "./initialization"

  additional_policy_arns          = var.initialization_additional_policy_arns
  create_service_linked_role      = var.create_service_linked_role
  create_service_roles            = var.create_service_roles
  max_session_duration            = var.initialization_max_session_duration
  path                            = var.initialization_path
  permissions_boundary            = var.initialization_permissions_boundary
  service_linked_role_description = var.service_linked_role_description
  tags                            = var.tags
}

###########################
# Replication Configuration Templates (composition)
###########################

module "replication_configuration_template" {
  source = "./replication_configuration_template"

  templates = local.templates
  tags      = var.tags
}
