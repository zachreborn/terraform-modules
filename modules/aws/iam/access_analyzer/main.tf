###########################
# Provider Configuration
###########################
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

###########################
# Delegated Administrator
###########################
resource "aws_organizations_delegated_administrator" "this" {
  count             = var.register_delegated_admin ? 1 : 0
  provider          = aws.organization_management_account
  account_id        = var.admin_account_id
  service_principal = "access-analyzer.amazonaws.com"

  lifecycle {
    precondition {
      condition     = var.admin_account_id != null
      error_message = "admin_account_id must be set when register_delegated_admin is true."
    }
  }
}

###########################
# Access Analyzer
###########################
resource "aws_accessanalyzer_analyzer" "this" {
  depends_on    = [aws_organizations_delegated_administrator.this]
  provider      = aws.organization_security_account
  analyzer_name = var.analyzer_name
  type          = var.analyzer_type
  tags          = merge(tomap({ Name = var.analyzer_name }), var.tags)

  dynamic "configuration" {
    for_each = (var.unused_access_age != null || length(var.unused_access_analysis_rule_exclusions) > 0 || length(var.internal_access_analysis_rule_inclusions) > 0) ? [1] : []
    content {
      dynamic "unused_access" {
        for_each = (var.unused_access_age != null || length(var.unused_access_analysis_rule_exclusions) > 0) ? [1] : []
        content {
          unused_access_age = var.unused_access_age

          dynamic "analysis_rule" {
            for_each = length(var.unused_access_analysis_rule_exclusions) > 0 ? [1] : []
            content {
              dynamic "exclusion" {
                for_each = var.unused_access_analysis_rule_exclusions
                content {
                  account_ids   = exclusion.value.account_ids
                  resource_tags = exclusion.value.resource_tags
                }
              }
            }
          }
        }
      }

      dynamic "internal_access" {
        for_each = length(var.internal_access_analysis_rule_inclusions) > 0 ? [1] : []
        content {
          dynamic "analysis_rule" {
            for_each = length(var.internal_access_analysis_rule_inclusions) > 0 ? [1] : []
            content {
              dynamic "inclusion" {
                for_each = var.internal_access_analysis_rule_inclusions
                content {
                  account_ids    = inclusion.value.account_ids
                  resource_arns  = inclusion.value.resource_arns
                  resource_types = inclusion.value.resource_types
                }
              }
            }
          }
        }
      }
    }
  }
}

###########################
# Archive Rules
###########################
resource "aws_accessanalyzer_archive_rule" "this" {
  for_each      = var.archive_rules
  provider      = aws.organization_security_account
  analyzer_name = aws_accessanalyzer_analyzer.this.analyzer_name
  rule_name     = each.key

  dynamic "filter" {
    for_each = each.value.filter
    content {
      criteria = filter.value.criteria
      eq       = filter.value.eq
      neq      = filter.value.neq
      contains = filter.value.contains
      exists   = filter.value.exists
    }
  }
}
