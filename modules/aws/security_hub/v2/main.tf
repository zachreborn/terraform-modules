# This module manages the unified AWS Security Hub service ("V2"), the 2026
# release that uses the OCSF schema and correlates signals across GuardDuty,
# Inspector, Macie, and Security Hub CSPM into prioritized exposures. It is
# distinct from Security Hub CSPM (managed by the sibling module at
# ../organization) and the two services coexist.
#
# IMPORTANT: The AWS provider does not yet expose an org-level resource for the
# unified service (there is no V2 equivalent of
# aws_securityhub_organization_admin_account or
# aws_securityhub_organization_configuration). This module therefore enables the
# unified service and its aggregator/automation rules in the delegated security
# (administrator) account. Delegated-administrator designation is inherited from
# the Security Hub CSPM delegated administrator (see ../organization), and
# org-wide member auto-enablement is performed via console/API configuration
# policies that are not yet available in Terraform.
###########################################################
# Provider Configuration
###########################################################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.46.0"
      configuration_aliases = [aws.organization_security_account]
    }
  }
}

###########################################################
# Security Hub V2 Account
###########################################################
# Enables the unified Security Hub (V2) in the delegated security account. This
# turns on the per-resource Essentials plan (30-day free trial, then billed).
resource "aws_securityhub_account_v2" "this" {
  provider = aws.organization_security_account

  tags = var.tags
}

###########################################################
# Security Hub V2 Finding Aggregator
###########################################################
# Cross-Region aggregation for the unified service. Required before any
# automation rules can be created.
resource "aws_securityhub_aggregator_v2" "this" {
  count    = var.enable_finding_aggregation ? 1 : 0
  provider = aws.organization_security_account

  region_linking_mode = var.region_linking_mode
  linked_regions      = var.linked_regions

  tags = var.tags

  depends_on = [aws_securityhub_account_v2.this]
}

###########################################################
# Security Hub V2 Automation Rules
###########################################################
# OCSF automation rules. Must be created in the aggregation (home) Region and
# require an existing aggregator.
resource "aws_securityhub_automation_rule_v2" "this" {
  for_each = var.automation_rules
  provider = aws.organization_security_account

  rule_name   = each.key
  description = each.value.description
  rule_order  = each.value.rule_order
  rule_status = each.value.rule_status

  criteria {
    ocsf_finding_criteria_json = each.value.ocsf_finding_criteria_json
  }

  action {
    type = each.value.action_type

    dynamic "finding_fields_update" {
      for_each = each.value.finding_fields_update != null ? [each.value.finding_fields_update] : []
      content {
        comment     = finding_fields_update.value.comment
        severity_id = finding_fields_update.value.severity_id
        status_id   = finding_fields_update.value.status_id
      }
    }

    dynamic "external_integration_configuration" {
      for_each = each.value.external_integration_connector_arn != null ? [each.value.external_integration_connector_arn] : []
      content {
        connector_arn = external_integration_configuration.value
      }
    }
  }

  tags = var.tags

  depends_on = [aws_securityhub_aggregator_v2.this]

  lifecycle {
    precondition {
      condition     = var.enable_finding_aggregation
      error_message = "automation_rules require enable_finding_aggregation = true, because a Security Hub V2 aggregator must exist in the aggregation (home) Region before automation rules can be created."
    }
  }
}
