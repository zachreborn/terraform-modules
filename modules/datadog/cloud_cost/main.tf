###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = ">= 4.11.0"
    }
  }
}

###########################
# Module Composition
###########################
module "aws_cur_config" {
  source = "./aws_cur_config"

  aws_cur_configs = var.config.aws_cur_configs
}

module "aws_ccm_config" {
  source = "./aws_ccm_config"

  ccm_configs = var.config.ccm_configs
}

module "budget" {
  source = "./budget"

  budgets = var.config.budgets
}

module "custom_allocation_rule" {
  source = "./custom_allocation_rule"

  allocation_rules              = var.config.allocation_rules
  enable_rule_order             = var.config.enable_rule_order
  rule_order                    = var.config.rule_order
  override_ui_defined_resources = var.config.override_ui_defined_resources
}
