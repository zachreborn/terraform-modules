###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

###########################
# Data Sources
###########################


###########################
# Locals
###########################

###########################
# Module Configuration
###########################

###########################
# Amplify App
###########################
resource "aws_amplify_app" "this" {
  access_token                  = var.access_token
  auto_branch_creation_patterns = var.auto_branch_creation_patterns
  basic_auth_credentials        = var.basic_auth_credentials
  build_spec                    = var.build_spec
  custom_headers                = var.custom_headers
  description                   = var.description
  enable_auto_branch_creation   = var.enable_auto_branch_creation
  enable_basic_auth             = var.enable_basic_auth
  enable_branch_auto_build      = var.enable_branch_auto_build
  enable_branch_auto_deletion   = var.enable_branch_auto_deletion
  environment_variables         = var.environment_variables
  name                          = var.name
  iam_service_role_arn          = var.iam_service_role_arn
  oauth_token                   = var.oauth_token
  platform                      = var.platform
  repository                    = var.repository
  tags                          = var.tags

  dynamic "auto_branch_creation_config" {
    for_each = var.auto_branch_creation_config != null ? var.auto_branch_creation_config : {}
    content {
      basic_auth_credentials        = each.value.basic_auth_credentials
      build_spec                    = each.value.build_spec
      enable_auto_build             = each.value.enable_auto_build
      enable_basic_auth             = each.value.enable_basic_auth
      enable_performance_mode       = each.value.enable_performance_mode
      enable_pull_request_preview   = each.value.enable_pull_request_preview
      environment_variables         = each.value.environment_variables
      framework                     = each.value.framework
      pull_request_environment_name = each.value.pull_request_environment_name
      stage                         = each.value.stage
    }
  }

  dynamic "cache_config" {
    for_each = var.cache_config_type != null ? [true] : []
    content {
      type = var.cache_config_type
    }
  }
  dynamic "custom_rule" {
    for_each = var.custom_rules != null ? var.custom_rules : {}
    content {
      condition = each.value.condition
      source    = each.value.source
      status    = each.value.status
      target    = each.value.target
    }
  }
}

###########################
# Amplify App Branch
###########################
resource "aws_amplify_branch" "this" {
  for_each                      = var.branches != null ? var.branches : {}
  app_id                        = aws_amplify_app.this.id
  basic_auth_credentials        = each.value.basic_auth_credentials
  branch_name                   = each.value.branch_name
  description                   = each.value.description
  display_name                  = each.value.display_name
  enable_auto_build             = each.value.enable_auto_build
  enable_basic_auth             = each.value.enable_basic_auth
  enable_notification           = each.value.enable_notification
  enable_performance_mode       = each.value.enable_performance_mode
  enable_pull_request_preview   = each.value.enable_pull_request_preview
  environment_variables         = each.value.environment_variables
  framework                     = each.value.framework
  pull_request_environment_name = each.value.pull_request_environment_name
  stage                         = each.value.stage
  tags                          = var.tags
  ttl                           = each.value.ttl
}

###########################
# Amplify App Domain Association
###########################
resource "aws_amplify_domain_association" "this" {
  # for_each               = var.branches.domain_name != null ? var.branches : {}
  for_each               = var.branches
  app_id                 = aws_amplify_app.this.id
  domain_name            = each.value.domain_name
  enable_auto_sub_domain = each.value.enable_auto_sub_domain
  wait_for_verification  = each.value.wait_for_verification
  dynamic "certificate_settings" {
    for_each = each.value.enable_certificate ? [true] : []
    content {
      custom_certificate_arn = each.value.custom_certificate_arn
      type                   = each.value.certificate_type
    }
  }

  dynamic "sub_domain" {
    for_each = each.value.sub_domains != null ? each.value.sub_domains : []
    content {
      branch_name = each.value.branch_name
      prefix      = each.value.prefix
    }
  }
}
