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


  ###########################
  # Amplify App Branch
  ###########################
  dynamic "auto_branch_creation_config" {
    for_each = var.auto_branch_creation_config != null ? var.auto_branch_creation_config : {}
    content {
      basic_auth_credentials        = auto_branch_creation_config.value.basic_auth_credentials
      build_spec                    = auto_branch_creation_config.value.build_spec
      enable_auto_build             = auto_branch_creation_config.value.enable_auto_build
      enable_basic_auth             = auto_branch_creation_config.value.enable_basic_auth
      enable_performance_mode       = auto_branch_creation_config.value.enable_performance_mode
      enable_pull_request_preview   = auto_branch_creation_config.value.enable_pull_request_preview
      environment_variables         = auto_branch_creation_config.value.environment_variables
      framework                     = auto_branch_creation_config.value.framework
      pull_request_environment_name = auto_branch_creation_config.value.pull_request_environment_name
      stage                         = auto_branch_creation_config.value.stage
    }
  }

  dynamic "cache_config" {
    for_each = var.cache_config_type != null ? 1 : 0
    content {
      type = var.cache_config_type
    }
  }
  dynamic "custom_rule" {
    for_each = var.custom_rules != null ? var.custom_rules : {}
    content {
      condition = custom_rule.value.condition
      source    = custom_rule.value.source
      status    = custom_rule.value.status
      target    = custom_rule.value.target
    }
  }
}

###########################
# Amplify App Backend
###########################
resource "aws_amplify_branch" "this" {
  for_each                      = var.branches != null ? var.branches : {}
  app_id                        = aws_amplify_app.this.id
  basic_auth_credentials        = branch.value.basic_auth_credentials
  branch_name                   = branch.value.branch_name
  description                   = branch.value.description
  display_name                  = branch.value.display_name
  enable_auto_build             = branch.value.enable_auto_build
  enable_basic_auth             = branch.value.enable_basic_auth
  enable_notification           = branch.value.enable_notification
  enable_performance_mode       = branch.value.enable_performance_mode
  enable_pull_request_preview   = branch.value.enable_pull_request_preview
  environment_variables         = branch.value.environment_variables
  framework                     = branch.value.framework
  pull_request_environment_name = branch.value.pull_request_environment_name
  stage                         = branch.value.stage
  tags                          = var.tags
  ttl                           = branch.value.ttl
}

###########################
# Amplify App Domain Association
###########################
resource "aws_amplify_domain_association" "this" {
  for_each               = var.domains != null ? var.domains : {}
  app_id                 = aws_amplify_app.this.id
  domain_name            = domain.value.domain_name
  enable_auto_sub_domain = domain.value.enable_auto_sub_domain
  wait_for_verification  = domain.value.wait_for_verification
  dynamic "certificate_settings" {
    for_each = domain.value.enable_certificate ? 1 : 0
    content {
      custom_certificate_arn = domain.value.custom_certificate_arn
      type                   = domain.value.certificate_type
    }
  }

  dynamic "sub_domain" {
    for_each = domain.value.sub_domains != null ? domain.value.sub_domains : {}
    content {
      branch_name = sub_domain.value.branch_name
      prefix      = sub_domain.value.prefix
    }
  }
}
