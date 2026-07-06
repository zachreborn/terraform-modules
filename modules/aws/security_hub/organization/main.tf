# This module manages AWS Security Hub CSPM (Cloud Security Posture Management),
# the classic Security Hub service that produces ASFF findings and runs the
# standards checks (AWS Foundational Security Best Practices, CIS, PCI DSS,
# NIST 800-53). In 2026 AWS renamed the classic service to "Security Hub CSPM"
# and reassigned the name "AWS Security Hub" to a new unified service (OCSF,
# cross-service correlation). Both coexist and CSPM is not deprecated. The new
# unified service is managed by the sibling module at ../v2.
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.0.0"
      configuration_aliases = [aws.organization_management_account, aws.organization_security_account]
    }
  }
}

###########################################################
# Locals
###########################################################
locals {
  # Central configuration requires auto_enable = false and
  # auto_enable_standards = "NONE" (those behaviors are governed by
  # configuration policies instead). Coerce them here so callers cannot produce
  # an invalid combination when configuration_type is CENTRAL.
  is_central            = var.configuration_type == "CENTRAL"
  auto_enable           = local.is_central ? false : var.auto_enable
  auto_enable_standards = local.is_central ? "NONE" : var.auto_enable_standards

  # Flatten configuration_policies into policy/target pairs for association.
  configuration_policy_associations = local.is_central ? {
    for assoc in flatten([
      for name, cfg in var.configuration_policies : [
        for target_id in cfg.target_ids : {
          policy    = name
          target_id = target_id
        }
      ]
    ]) : "${assoc.policy}-${assoc.target_id}" => assoc
  } : {}
}

###########################################################
# Security Hub CSPM Account
###########################################################
# Enables Security Hub CSPM in the delegated security account.
resource "aws_securityhub_account" "this" {
  provider                 = aws.organization_security_account
  enable_default_standards = var.enable_default_standards
}

###########################################################
# Security Hub CSPM Delegated Administrator
###########################################################
# Delegates Security Hub CSPM administration from the organization management
# account to the security account. Per AWS, delegating CSPM to a non-management
# account also makes that account the delegated administrator for the new
# unified AWS Security Hub, so no separate V2 delegation resource is required.
resource "aws_securityhub_organization_admin_account" "this" {
  depends_on       = [aws_securityhub_account.this]
  provider         = aws.organization_management_account
  admin_account_id = var.admin_account_id
}

###########################################################
# Security Hub CSPM Finding Aggregator
###########################################################
# Created before the organization configuration because CSPM central
# configuration requires an existing finding aggregator. This ordering is also
# valid for LOCAL configuration.
resource "aws_securityhub_finding_aggregator" "this" {
  provider          = aws.organization_security_account
  depends_on        = [aws_securityhub_organization_admin_account.this]
  linking_mode      = var.linking_mode
  specified_regions = var.specified_regions
}

###########################################################
# Security Hub CSPM Organization Configuration
###########################################################
resource "aws_securityhub_organization_configuration" "this" {
  provider   = aws.organization_security_account
  depends_on = [aws_securityhub_finding_aggregator.this]

  auto_enable           = local.auto_enable
  auto_enable_standards = local.auto_enable_standards

  # Only emit the block for CENTRAL configuration. Omitting it for LOCAL keeps
  # the historical default behavior and avoids a diff for existing callers.
  dynamic "organization_configuration" {
    for_each = local.is_central ? [1] : []
    content {
      configuration_type = "CENTRAL"
    }
  }
}

###########################################################
# Security Hub CSPM Configuration Policies (CENTRAL only)
###########################################################
resource "aws_securityhub_configuration_policy" "this" {
  for_each = local.is_central ? var.configuration_policies : {}
  provider = aws.organization_security_account

  name        = each.key
  description = each.value.description

  configuration_policy {
    service_enabled       = each.value.service_enabled
    enabled_standard_arns = each.value.service_enabled ? each.value.enabled_standard_arns : []

    dynamic "security_controls_configuration" {
      for_each = each.value.service_enabled ? [1] : []
      content {
        # enabled and disabled control identifiers are mutually exclusive in the
        # AWS API. If enabled_control_identifiers is provided it takes
        # precedence; otherwise the disabled list is used (empty means all
        # controls enabled).
        enabled_control_identifiers  = length(each.value.enabled_control_identifiers) > 0 ? each.value.enabled_control_identifiers : null
        disabled_control_identifiers = length(each.value.enabled_control_identifiers) > 0 ? null : each.value.disabled_control_identifiers
      }
    }
  }

  depends_on = [aws_securityhub_organization_configuration.this]
}

resource "aws_securityhub_configuration_policy_association" "this" {
  for_each = local.configuration_policy_associations
  provider = aws.organization_security_account

  policy_id = aws_securityhub_configuration_policy.this[each.value.policy].id
  target_id = each.value.target_id

  depends_on = [aws_securityhub_configuration_policy.this]
}
