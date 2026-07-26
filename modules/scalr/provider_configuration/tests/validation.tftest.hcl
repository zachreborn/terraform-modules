mock_provider "scalr" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    provider_configurations = {
      aws_prod = {
        account_id = "acc-xxxxxxxxxx"
        aws = {
          credentials_type = "access_keys"
          access_key       = "my-access-key"
        }
      }
    }
    provider_configuration_secrets = {
      aws_prod = {
        aws_secret_key = "my-secret-key"
      }
    }
  }

  assert {
    condition     = length(scalr_provider_configuration.this) == 1
    error_message = "Expected exactly one provider configuration to be planned."
  }
}

run "rejects_entry_with_no_provider_block" {
  command = plan

  variables {
    provider_configurations = {
      broken = {
        account_id = "acc-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.provider_configurations]
}

run "rejects_entry_with_two_provider_blocks" {
  command = plan

  variables {
    provider_configurations = {
      broken = {
        account_id = "acc-xxxxxxxxxx"
        aws = {
          credentials_type = "access_keys"
        }
        azurerm = {
          client_id = "my-client-id"
          tenant_id = "my-tenant-id"
        }
      }
    }
  }

  expect_failures = [var.provider_configurations]
}

run "rejects_aws_entry_with_invalid_credentials_type" {
  command = plan

  variables {
    provider_configurations = {
      broken = {
        account_id = "acc-xxxxxxxxxx"
        aws = {
          credentials_type = "not_a_real_type"
        }
      }
    }
  }

  expect_failures = [var.provider_configurations]
}

run "rejects_azurerm_entry_with_invalid_auth_type" {
  command = plan

  variables {
    provider_configurations = {
      broken = {
        account_id = "acc-xxxxxxxxxx"
        azurerm = {
          client_id = "my-client-id"
          tenant_id = "my-tenant-id"
          auth_type = "not_a_real_type"
        }
      }
    }
  }

  expect_failures = [var.provider_configurations]
}

run "rejects_google_entry_with_invalid_auth_type" {
  command = plan

  variables {
    provider_configurations = {
      broken = {
        account_id = "acc-xxxxxxxxxx"
        google = {
          auth_type = "not_a_real_type"
        }
      }
    }
  }

  expect_failures = [var.provider_configurations]
}

run "rejects_custom_entry_with_no_arguments" {
  command = plan

  variables {
    provider_configurations = {
      broken = {
        account_id = "acc-xxxxxxxxxx"
        custom = {
          provider_name = "kubernetes"
        }
      }
    }
  }

  expect_failures = [var.provider_configurations]
}

run "rejects_provider_configuration_defaults_entry_with_both_key_and_id" {
  command = plan

  variables {
    provider_configuration_defaults = {
      broken = {
        provider_configuration_key = "aws_prod"
        provider_configuration_id  = "pcfg-xxxxxxxxxx"
        environment_id             = "env-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.provider_configuration_defaults]
}

run "rejects_provider_configuration_defaults_entry_with_neither_key_nor_id" {
  command = plan

  variables {
    provider_configuration_defaults = {
      broken = {
        environment_id = "env-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.provider_configuration_defaults]
}

run "rejects_provider_configuration_defaults_entry_with_unknown_key" {
  command = plan

  variables {
    provider_configuration_defaults = {
      broken = {
        provider_configuration_key = "does_not_exist"
        environment_id             = "env-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.provider_configuration_defaults]
}
