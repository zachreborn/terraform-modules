###########################
# Provider Configuration
###########################
terraform {
  # >= 1.9.0 is required because this module's provider_configuration_key validation (variables.tf)
  # references var.provider_configurations from within var.provider_configuration_defaults's
  # validation block. Terraform and OpenTofu both added support for referencing other variables/
  # locals in variable validation in their respective 1.9.0 releases, so this floor is satisfied by
  # either tool.
  required_version = ">= 1.9.0"
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.17.0"
    }
  }
}

###########################
# Locals
###########################
locals {
  # Sensitive credential values, keyed the same way as var.provider_configurations. Referencing
  # this local (rather than var.provider_configuration_secrets directly) inside resource
  # attributes below is purely stylistic; either is safe here since neither is used as a for_each
  # source.
  secrets = var.provider_configuration_secrets

  # Resolve each provider_configuration_defaults entry's provider_configuration_id: either a
  # literal, externally-managed ID, or a reference (by key) to a provider configuration created
  # by this same module call.
  resolved_defaults = {
    for k, v in var.provider_configuration_defaults : k => {
      environment_id            = v.environment_id
      provider_configuration_id = v.provider_configuration_id != null ? v.provider_configuration_id : scalr_provider_configuration.this[v.provider_configuration_key].id
    }
  }
}

###########################
# Provider Configurations
###########################
resource "scalr_provider_configuration" "this" {
  for_each = var.provider_configurations

  name                   = coalesce(each.value.name, each.key)
  account_id             = each.value.account_id
  apply_only             = each.value.apply_only
  environments           = each.value.environments
  export_shell_variables = each.value.export_shell_variables
  owners                 = each.value.owners
  tag_ids                = each.value.tag_ids

  dynamic "aws" {
    for_each = each.value.aws != null ? [each.value.aws] : []
    content {
      credentials_type    = aws.value.credentials_type
      access_key          = aws.value.access_key
      account_type        = aws.value.account_type
      audience            = aws.value.audience
      credentials_source  = aws.value.credentials_source
      external_id         = aws.value.external_id
      role_arn            = aws.value.role_arn
      secret_key          = try(local.secrets[each.key].aws_secret_key, null)
      trusted_entity_type = aws.value.trusted_entity_type

      dynamic "default_tags" {
        for_each = aws.value.default_tags != null ? [aws.value.default_tags] : []
        content {
          tags     = default_tags.value.tags
          strategy = default_tags.value.strategy
        }
      }
    }
  }

  dynamic "azurerm" {
    for_each = each.value.azurerm != null ? [each.value.azurerm] : []
    content {
      client_id       = azurerm.value.client_id
      tenant_id       = azurerm.value.tenant_id
      audience        = azurerm.value.audience
      auth_type       = azurerm.value.auth_type
      client_secret   = try(local.secrets[each.key].azurerm_client_secret, null)
      subscription_id = azurerm.value.subscription_id
    }
  }

  dynamic "google" {
    for_each = each.value.google != null ? [each.value.google] : []
    content {
      auth_type              = google.value.auth_type
      credentials            = try(local.secrets[each.key].google_credentials, null)
      project                = google.value.project
      service_account_email  = google.value.service_account_email
      use_default_project    = google.value.use_default_project
      workload_provider_name = google.value.workload_provider_name

      dynamic "default_labels" {
        for_each = google.value.default_labels != null ? [google.value.default_labels] : []
        content {
          labels   = default_labels.value.labels
          strategy = default_labels.value.strategy
        }
      }
    }
  }

  dynamic "scalr" {
    for_each = each.value.scalr != null ? [each.value.scalr] : []
    content {
      hostname = scalr.value.hostname
      token    = try(local.secrets[each.key].scalr_token, null)
    }
  }

  dynamic "custom" {
    for_each = each.value.custom != null ? [each.value.custom] : []
    content {
      provider_name = custom.value.provider_name

      dynamic "argument" {
        for_each = custom.value.arguments
        content {
          name        = argument.value.name
          value       = argument.value.sensitive ? try(local.secrets[each.key].custom_argument_values[argument.value.name], null) : argument.value.value
          description = argument.value.description
          hcl         = argument.value.hcl
          sensitive   = argument.value.sensitive
        }
      }
    }
  }
}

###########################
# Provider Configuration Defaults (companion submodule)
###########################
module "default" {
  source = "./default"

  provider_configuration_defaults = local.resolved_defaults
}
