# Native OpenTofu tests for the module-test arguments of modules/scalr/provider_configuration
# (is_allowed_in_module_test input and is_used_in_module_test output, scalr provider >= 3.20.0).
#
# The existing main/validation/wiring test files are intentionally left untouched: they prove the
# existing interface stayed backward compatible.
#
# Run offline with:
#   tofu -chdir=modules/scalr/provider_configuration init -backend=false
#   tofu -chdir=modules/scalr/provider_configuration test

mock_provider "scalr" {
  mock_resource "scalr_provider_configuration" {
    defaults = {
      id                     = "pcfg-xxxxxxxxxx"
      is_used_in_module_test = false
    }
  }

  mock_resource "scalr_provider_configuration_default" {
    defaults = {
      id = "env-xxxxxxxxxx/pcfg-xxxxxxxxxx"
    }
  }
}

run "is_allowed_in_module_test_defaults_to_false" {
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
  }

  assert {
    condition     = scalr_provider_configuration.this["aws_prod"].is_allowed_in_module_test == false
    error_message = "is_allowed_in_module_test should default to false (matches the provider default)."
  }

  assert {
    condition     = output.is_used_in_module_test["aws_prod"] == false
    error_message = "is_used_in_module_test output should expose the (mocked) read-only attribute under the logical key."
  }
}

run "is_allowed_in_module_test_true_is_passed_through" {
  command = plan

  variables {
    provider_configurations = {
      aws_module_test = {
        account_id                = "acc-xxxxxxxxxx"
        environments              = ["*"]
        is_allowed_in_module_test = true
        aws = {
          credentials_type = "oidc"
          role_arn         = "arn:aws:iam::123456789012:role/scalr-oidc-role"
          audience         = "aws.scalr-run-workload"
        }
      }
    }
  }

  assert {
    condition     = scalr_provider_configuration.this["aws_module_test"].is_allowed_in_module_test == true
    error_message = "is_allowed_in_module_test = true should be passed through to the resource."
  }

  assert {
    condition     = output.ids["aws_module_test"] != null
    error_message = "ids output should still contain the entry."
  }
}

run "is_allowed_in_module_test_is_set_per_entry_across_provider_types" {
  command = plan

  variables {
    provider_configurations = {
      aws_module_test = {
        account_id                = "acc-xxxxxxxxxx"
        is_allowed_in_module_test = true
        aws = {
          credentials_type = "oidc"
          role_arn         = "arn:aws:iam::123456789012:role/scalr-oidc-role"
          audience         = "aws.scalr-run-workload"
        }
      }
      azurerm_module_test = {
        account_id                = "acc-xxxxxxxxxx"
        is_allowed_in_module_test = true
        azurerm = {
          auth_type       = "oidc"
          audience        = "scalr-workload-identity"
          client_id       = "my-client-id"
          tenant_id       = "my-tenant-id"
          subscription_id = "my-subscription-id"
        }
      }
      k8s = {
        account_id = "acc-xxxxxxxxxx"
        custom = {
          provider_name = "kubernetes"
          arguments = [
            { name = "host", value = "https://k8s.example.com" },
          ]
        }
      }
    }
  }

  assert {
    condition     = scalr_provider_configuration.this["aws_module_test"].is_allowed_in_module_test == true
    error_message = "The aws entry should allow module tests."
  }

  assert {
    condition     = scalr_provider_configuration.this["azurerm_module_test"].is_allowed_in_module_test == true
    error_message = "The azurerm entry should allow module tests."
  }

  assert {
    condition     = scalr_provider_configuration.this["k8s"].is_allowed_in_module_test == false
    error_message = "An entry that does not set is_allowed_in_module_test should keep the default (false)."
  }

  assert {
    condition     = length(output.is_used_in_module_test) == 3
    error_message = "is_used_in_module_test output should have one key per provider configuration."
  }
}

run "is_used_in_module_test_output_is_keyed_like_ids" {
  command = plan

  override_resource {
    target = scalr_provider_configuration.this["linked"]
    values = {
      id                     = "pcfg-linked00000"
      is_used_in_module_test = true
    }
  }

  override_resource {
    target = scalr_provider_configuration.this["unlinked"]
    values = {
      id                     = "pcfg-unlinked000"
      is_used_in_module_test = false
    }
  }

  variables {
    provider_configurations = {
      linked = {
        account_id                = "acc-xxxxxxxxxx"
        is_allowed_in_module_test = true
        aws = {
          credentials_type = "oidc"
          role_arn         = "arn:aws:iam::123456789012:role/scalr-oidc-role"
          audience         = "aws.scalr-run-workload"
        }
      }
      unlinked = {
        account_id = "acc-xxxxxxxxxx"
        aws = {
          credentials_type = "oidc"
          role_arn         = "arn:aws:iam::123456789012:role/scalr-oidc-role"
          audience         = "aws.scalr-run-workload"
        }
      }
    }
  }

  assert {
    condition     = output.is_used_in_module_test["linked"] == true
    error_message = "is_used_in_module_test output should report true for the linked configuration."
  }

  assert {
    condition     = output.is_used_in_module_test["unlinked"] == false
    error_message = "is_used_in_module_test output should report false for the unlinked configuration."
  }

  assert {
    condition     = keys(output.is_used_in_module_test) == keys(output.ids)
    error_message = "is_used_in_module_test output should use the same keys as the ids output."
  }
}

run "is_allowed_in_module_test_composes_with_defaults_submodule" {
  command = plan

  variables {
    provider_configurations = {
      aws_module_test = {
        account_id                = "acc-xxxxxxxxxx"
        environments              = ["*"]
        is_allowed_in_module_test = true
        aws = {
          credentials_type = "oidc"
          role_arn         = "arn:aws:iam::123456789012:role/scalr-oidc-role"
          audience         = "aws.scalr-run-workload"
        }
      }
    }
    provider_configuration_defaults = {
      aws_module_test_default = {
        provider_configuration_key = "aws_module_test"
        environment_id             = "env-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = scalr_provider_configuration.this["aws_module_test"].is_allowed_in_module_test == true
    error_message = "is_allowed_in_module_test should be unaffected by composing the defaults submodule."
  }

  assert {
    condition     = length(output.default_ids) == 1
    error_message = "The defaults submodule should still be planned alongside module-test-enabled configurations."
  }
}

run "empty_map_has_empty_is_used_in_module_test_output" {
  command = plan

  assert {
    condition     = length(output.is_used_in_module_test) == 0
    error_message = "is_used_in_module_test output should be empty when no provider configurations are set."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
