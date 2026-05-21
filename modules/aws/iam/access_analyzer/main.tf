##############################
# Provider Configuration
##############################
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

##############################
# Delegated Administrator
##############################
resource "aws_organizations_delegated_administrator" "this" {
  count             = var.register_delegated_admin ? 1 : 0
  provider          = aws.organization_management_account
  account_id        = var.admin_account_id
  service_principal = "access-analyzer.amazonaws.com"
}

##############################
# Access Analyzer
##############################
resource "aws_accessanalyzer_analyzer" "this" {
  depends_on    = [aws_organizations_delegated_administrator.this]
  provider      = aws.organization_security_account
  analyzer_name = var.analyzer_name
  type          = var.analyzer_type
  tags          = var.tags

  dynamic "archive_rule" {
    for_each = var.archive_rules
    content {
      rule_name = archive_rule.value.rule_name

      dynamic "filter" {
        for_each = archive_rule.value.filter
        content {
          criteria = filter.value.criteria
          eq       = filter.value.eq
          neq      = filter.value.neq
          contains = filter.value.contains
          exists   = filter.value.exists
        }
      }
    }
  }
}
