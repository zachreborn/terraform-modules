terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

############################
# Data Sources
############################
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_organizations_organization" "current" {}

############################
# Locals
############################





############################
# WAF ACL
############################

resource "aws_wafv2_web_acl" "waf_acl" {
  name        = var.name
  scope       = var.scope # REGIONAL(default) or CLOUDFRONT
  description = var.description
  dynamic "default_action" {
    # TODO: start here for default action and add logic for allow/block for default.  
  }
  dynamic "rule" {
    for_each = each.value.rule != null ? each.value.rule : {}
    content {
      name     = rule.value.name
      priority = rule.value.priority
      action {
        block {}
      }
      statement {
        managed_rule_group_statement {
          name        = rule.value.managed_rule_group_statement.name
          vendor_name = rule.value.managed_rule_group_statement.vendor_name
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = rule.value.visibility_config.cloudwatch_metrics_enabled
        metric_name                = rule.value.visibility_config.metric_name
        sampled_requests_enabled   = rule.value.visibility_config.sampled_requests_enabled
      }
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = var.visibility_config.cloudwatch_metrics_enabled # default true
    metric_name                = var.visibility_config.metric_name                # default "waf-acl" maybe change to var.name
    sampled_requests_enabled   = var.visibility_config.sampled_requests_enabled   # default true
  }
}
