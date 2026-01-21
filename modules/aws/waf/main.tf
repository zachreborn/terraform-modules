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
# IP Sets
############################

resource "aws_wafv2_ip_set" "this" {
  for_each = var.ip_sets

  name               = each.value.name
  description        = each.value.description
  scope              = var.scope
  ip_address_version = each.value.ip_address_version
  addresses          = each.value.addresses

  tags = {
    Name = each.value.name
  }
}

############################
# WAF ACL
############################

resource "aws_wafv2_web_acl" "this" {
  name        = var.name
  scope       = var.scope # REGIONAL(default) or CLOUDFRONT
  description = var.description

  dynamic "default_action" {
    for_each = var.default_action.allow == true ? ["allow"] : ["block"]
    content {
      dynamic "allow" {
        for_each = var.default_action.allow == true ? ["allow"] : []
        content {}
      }
      dynamic "block" {
        for_each = var.default_action.block == true ? ["block"] : []
        content {}
      }
    }
  }
  dynamic "rule" {
    for_each = var.rule != null ? var.rule : {}
    content {
      name     = rule.value.name
      priority = rule.value.priority

      action {
        dynamic "allow" {
          for_each = rule.value.action == "allow" ? ["allow"] : []
          content {}
        }
        dynamic "block" {
          for_each = rule.value.action == "block" ? ["block"] : []
          content {}
        }
        dynamic "count" {
          for_each = rule.value.action == "count" ? ["count"] : []
          content {}
        }
      }

      statement {
        dynamic "managed_rule_group_statement" {
          for_each = rule.value.statement.managed_rule_group_statement != null ? [rule.value.statement.managed_rule_group_statement] : []
          content {
            name        = managed_rule_group_statement.value.name
            vendor_name = managed_rule_group_statement.value.vendor_name

            dynamic "rule_action_override" {
              for_each = managed_rule_group_statement.value.excluded_rules
              content {
                name = rule_action_override.value
                action_to_use {
                  count {}
                }
              }
            }
          }
        }

        dynamic "not_statement" {
          for_each = rule.value.statement.not_statement != null ? [rule.value.statement.not_statement] : []
          content {
            statement {
              ip_set_reference_statement {
                arn = not_statement.value.ip_set_reference_statement.arn
              }
            }
          }
        }

        dynamic "ip_set_reference_statement" {
          for_each = rule.value.statement.ip_set_reference_statement != null ? [rule.value.statement.ip_set_reference_statement] : []
          content {
            arn = ip_set_reference_statement.value.arn
          }
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
    cloudwatch_metrics_enabled = var.visibility_config.cloudwatch_metrics_enabled
    metric_name                = var.visibility_config.metric_name != null ? var.visibility_config.metric_name : var.name
    sampled_requests_enabled   = var.visibility_config.sampled_requests_enabled
  }
}

############################
# WAF Association
############################

resource "aws_wafv2_web_acl_association" "this" {
  count = var.associate_with_resource != null ? 1 : 0

  resource_arn = var.associate_with_resource
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
