mock_provider "scalr" {
  mock_resource "scalr_provider_configuration" {
    defaults = {
      id = "pcfg-xxxxxxxxxx"
    }
  }

  mock_resource "scalr_provider_configuration_default" {
    defaults = {
      id = "env-xxxxxxxxxx/pcfg-xxxxxxxxxx"
    }
  }
}

run "aws_entry_plans_successfully" {
  command = plan

  variables {
    provider_configurations = {
      aws_prod = {
        account_id   = "acc-xxxxxxxxxx"
        environments = ["*"]
        aws = {
          credentials_type = "access_keys"
          access_key       = "my-access-key"
          account_type     = "regular"
          default_tags = {
            tags     = { Environment = "prod" }
            strategy = "update"
          }
        }
      }
    }
    provider_configuration_secrets = {
      aws_prod = {
        # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
        aws_secret_key = "my-secret-key"
      }
    }
  }

  assert {
    condition     = length(scalr_provider_configuration.this) == 1
    error_message = "Expected exactly one provider configuration to be planned."
  }

  assert {
    condition     = output.ids["aws_prod"] != null
    error_message = "Expected the ids output to contain the aws_prod configuration."
  }

  assert {
    condition     = scalr_provider_configuration.this["aws_prod"].aws[0].secret_key == "my-secret-key"
    error_message = "Expected the secret_key to be resolved from provider_configuration_secrets."
  }
}

run "azurerm_entry_plans_successfully" {
  command = plan

  variables {
    provider_configurations = {
      azurerm_prod = {
        account_id = "acc-xxxxxxxxxx"
        azurerm = {
          client_id       = "my-client-id"
          tenant_id       = "my-tenant-id"
          subscription_id = "my-subscription-id"
        }
      }
    }
    provider_configuration_secrets = {
      azurerm_prod = {
        # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
        azurerm_client_secret = "my-client-secret"
      }
    }
  }

  assert {
    condition     = scalr_provider_configuration.this["azurerm_prod"].azurerm[0].client_secret == "my-client-secret"
    error_message = "Expected the client_secret to be resolved from provider_configuration_secrets."
  }
}

run "google_oidc_entry_plans_successfully" {
  command = plan

  variables {
    provider_configurations = {
      google_prod = {
        account_id = "acc-xxxxxxxxxx"
        google = {
          auth_type              = "oidc"
          project                = "my-project"
          workload_provider_name = "projects/123/locations/global/workloadIdentityPools/pool-name/providers/provider-name"
        }
      }
    }
  }

  assert {
    condition     = scalr_provider_configuration.this["google_prod"].google[0].auth_type == "oidc"
    error_message = "Expected the google auth_type to be set to oidc."
  }
}

run "scalr_entry_plans_successfully" {
  command = plan

  variables {
    provider_configurations = {
      scalr_main = {
        account_id = "acc-xxxxxxxxxx"
        scalr = {
          hostname = "scalr.host.example.com"
        }
      }
    }
    provider_configuration_secrets = {
      scalr_main = {
        # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
        scalr_token = "my-scalr-token"
      }
    }
  }

  assert {
    condition     = scalr_provider_configuration.this["scalr_main"].scalr[0].token == "my-scalr-token"
    error_message = "Expected the scalr token to be resolved from provider_configuration_secrets."
  }
}

run "custom_entry_with_sensitive_argument_plans_successfully" {
  command = plan

  variables {
    provider_configurations = {
      k8s = {
        account_id = "acc-xxxxxxxxxx"
        custom = {
          provider_name = "kubernetes"
          arguments = [
            { name = "host", value = "https://k8s.example.com" },
            { name = "password", sensitive = true },
          ]
        }
      }
    }
    provider_configuration_secrets = {
      k8s = {
        custom_argument_values = {
          # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
          password = "my-k8s-password"
        }
      }
    }
  }

  assert {
    condition     = [for a in scalr_provider_configuration.this["k8s"].custom[0].argument : a.value if a.name == "password"][0] == "my-k8s-password"
    error_message = "Expected the sensitive custom argument value to be resolved from provider_configuration_secrets."
  }

  assert {
    condition     = [for a in scalr_provider_configuration.this["k8s"].custom[0].argument : a.value if a.name == "host"][0] == "https://k8s.example.com"
    error_message = "Expected the non-sensitive custom argument value to come from provider_configurations directly."
  }
}

run "provider_configuration_defaults_conditional_branch_creates_default" {
  command = plan

  variables {
    provider_configurations = {
      aws_prod = {
        account_id   = "acc-xxxxxxxxxx"
        environments = ["*"]
        aws = {
          credentials_type = "oidc"
          role_arn         = "arn:aws:iam::123456789012:role/scalr-oidc-role"
          audience         = "aws.scalr-run-workload"
        }
      }
    }
    provider_configuration_defaults = {
      aws_prod_default = {
        provider_configuration_key = "aws_prod"
        environment_id             = "env-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(output.default_ids) == 1
    error_message = "Expected one default to be planned when provider_configuration_defaults has one entry."
  }
}

run "no_defaults_when_map_is_empty" {
  command = plan

  variables {
    provider_configurations = {
      aws_prod = {
        account_id   = "acc-xxxxxxxxxx"
        environments = ["*"]
        aws = {
          credentials_type = "access_keys"
          access_key       = "my-access-key"
        }
      }
    }
  }

  assert {
    condition     = length(output.default_ids) == 0
    error_message = "Expected no defaults when provider_configuration_defaults is not set."
  }
}
