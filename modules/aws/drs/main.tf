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
# Data Sources
###########################

# Resolves the provider's default region when var.region is not set, so the
# cross-region KMS guard below can compare a template's effective region
# against the shared key's actual region even when both are left at their
# provider defaults.
data "aws_region" "current" {}

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

  # The Region the shared key (created or supplied) actually lives in. KMS keys
  # are regional, so this is what the cross-region guard below compares each
  # template's effective Region against. ARNs embed the Region as their fourth
  # colon-delimited field (arn:PARTITION:SERVICE:REGION:ACCOUNT:RESOURCE).
  kms_key_region = (
    var.create_kms_key
    ? coalesce(var.region, data.aws_region.current.region)
    : (var.kms_key_arn != null ? element(split(":", var.kms_key_arn), 3) : null)
  )

  # Inject the resolved customer managed key into every template that did not
  # set one explicitly, and keep ebs_encryption consistent with it. A template
  # that supplies its own ebs_encryption_key_arn must resolve to CUSTOM even
  # when this module has no shared key of its own (create_kms_key = false and
  # no kms_key_arn), so the per-template override always takes effect.
  templates = {
    for key, template in var.templates : key => merge(template, {
      ebs_encryption = (
        template.ebs_encryption != null
        ? template.ebs_encryption
        : ((local.kms_key_enabled || template.ebs_encryption_key_arn != null) ? "CUSTOM" : "DEFAULT")
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
# built-in, provider-less resource exists solely to carry the preconditions
# below.
resource "terraform_data" "validate_kms_inputs" {
  lifecycle {
    precondition {
      condition     = !(var.create_kms_key && var.kms_key_arn != null)
      error_message = "create_kms_key and kms_key_arn are mutually exclusive. Set create_kms_key to false when supplying an existing kms_key_arn."
    }

    # KMS keys are regional. A template that relies on this module's shared
    # key (rather than supplying its own ebs_encryption_key_arn) must resolve
    # to the same Region that key lives in, or AWS will reject the template
    # with a cross-region KMS key error.
    precondition {
      condition = alltrue([
        for key, template in var.templates :
        template.ebs_encryption_key_arn != null || !local.kms_key_enabled || coalesce(template.region, var.region, data.aws_region.current.region) == local.kms_key_region
      ])
      error_message = "One or more entries in var.templates resolve to a region different from the shared KMS key's region (${coalesce(local.kms_key_region, "unknown")}). KMS keys are regional: give that template its own ebs_encryption_key_arn in the same region as staging_area_subnet_id, or set create_kms_key = false / ebs_encryption = \"DEFAULT\" for it."
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
