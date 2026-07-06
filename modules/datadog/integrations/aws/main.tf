###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = ">= 4.0.0"
    }
  }
}

###########################
# Locals
###########################
locals {
  role_accounts = { for k, v in var.aws_accounts : k => v if v.auth_config.aws_auth_config_role != null }
  keys_accounts = { for k, v in var.aws_accounts : k => v if v.auth_config.aws_auth_config_keys != null }
}

###########################
# Module Configuration
###########################

# Optional: create a Datadog-generated external ID for role-based auth
resource "datadog_integration_aws_external_id" "this" {
  for_each = { for k, v in local.role_accounts : k => v if v.create_external_id }
}

# Role-based authentication accounts
resource "datadog_integration_aws_account" "role" {
  for_each = local.role_accounts

  aws_account_id = each.value.aws_account_id
  aws_partition  = each.value.aws_partition
  account_tags   = each.value.account_tags

  auth_config {
    aws_auth_config_role {
      role_name   = each.value.auth_config.aws_auth_config_role.role_name
      external_id = try(datadog_integration_aws_external_id.this[each.key].id, each.value.auth_config.aws_auth_config_role.external_id)
    }
  }

  aws_regions {
    include_all  = each.value.aws_regions.include_all
    include_only = each.value.aws_regions.include_only
  }

  logs_config {
    lambda_forwarder {
      lambdas = each.value.logs_config.lambda_forwarder.lambdas
      sources = each.value.logs_config.lambda_forwarder.sources
      dynamic "log_source_config" {
        for_each = each.value.logs_config.lambda_forwarder.log_source_config != null ? [each.value.logs_config.lambda_forwarder.log_source_config] : []
        content {
          dynamic "tag_filters" {
            for_each = log_source_config.value.tag_filters
            content {
              source = tag_filters.value.source
              tags   = tag_filters.value.tags
            }
          }
        }
      }
    }
  }

  metrics_config {
    automute_enabled          = each.value.metrics_config.automute_enabled
    collect_cloudwatch_alarms = each.value.metrics_config.collect_cloudwatch_alarms
    collect_custom_metrics    = each.value.metrics_config.collect_custom_metrics
    enabled                   = each.value.metrics_config.enabled
    namespace_filters {
      exclude_only = each.value.metrics_config.namespace_filters.exclude_only
      include_only = each.value.metrics_config.namespace_filters.include_only
    }
    dynamic "tag_filters" {
      for_each = each.value.metrics_config.tag_filters
      content {
        namespace = tag_filters.value.namespace
        tags      = tag_filters.value.tags
      }
    }
  }

  resources_config {
    cloud_security_posture_management_collection = each.value.resources_config.cloud_security_posture_management_collection
    extended_collection                          = each.value.resources_config.extended_collection
  }

  traces_config {
    xray_services {
      include_all  = each.value.traces_config.xray_services.include_all
      include_only = each.value.traces_config.xray_services.include_only
    }
  }
}

# Access key-based authentication accounts
resource "datadog_integration_aws_account" "keys" {
  for_each = local.keys_accounts

  aws_account_id = each.value.aws_account_id
  aws_partition  = each.value.aws_partition
  account_tags   = each.value.account_tags

  auth_config {
    aws_auth_config_keys {
      access_key_id     = each.value.auth_config.aws_auth_config_keys.access_key_id
      secret_access_key = each.value.auth_config.aws_auth_config_keys.secret_access_key
    }
  }

  aws_regions {
    include_all  = each.value.aws_regions.include_all
    include_only = each.value.aws_regions.include_only
  }

  logs_config {
    lambda_forwarder {
      lambdas = each.value.logs_config.lambda_forwarder.lambdas
      sources = each.value.logs_config.lambda_forwarder.sources
      dynamic "log_source_config" {
        for_each = each.value.logs_config.lambda_forwarder.log_source_config != null ? [each.value.logs_config.lambda_forwarder.log_source_config] : []
        content {
          dynamic "tag_filters" {
            for_each = log_source_config.value.tag_filters
            content {
              source = tag_filters.value.source
              tags   = tag_filters.value.tags
            }
          }
        }
      }
    }
  }

  metrics_config {
    automute_enabled          = each.value.metrics_config.automute_enabled
    collect_cloudwatch_alarms = each.value.metrics_config.collect_cloudwatch_alarms
    collect_custom_metrics    = each.value.metrics_config.collect_custom_metrics
    enabled                   = each.value.metrics_config.enabled
    namespace_filters {
      exclude_only = each.value.metrics_config.namespace_filters.exclude_only
      include_only = each.value.metrics_config.namespace_filters.include_only
    }
    dynamic "tag_filters" {
      for_each = each.value.metrics_config.tag_filters
      content {
        namespace = tag_filters.value.namespace
        tags      = tag_filters.value.tags
      }
    }
  }

  resources_config {
    cloud_security_posture_management_collection = each.value.resources_config.cloud_security_posture_management_collection
    extended_collection                          = each.value.resources_config.extended_collection
  }

  traces_config {
    xray_services {
      include_all  = each.value.traces_config.xray_services.include_all
      include_only = each.value.traces_config.xray_services.include_only
    }
  }
}
