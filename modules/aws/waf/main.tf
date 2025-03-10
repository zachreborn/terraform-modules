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
  default_action {
    allow {}
  }
  rule {
    name     = "allow-all"
    priority = 1
    action {
      allow {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "allow-all"
      sampled_requests_enabled   = true
    }
  }
}
