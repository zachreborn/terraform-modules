mock_provider "scalr" {
  mock_resource "scalr_provider_configuration" {
    defaults = {
      id = "pcfg-mockedvalue1"
    }
  }

  mock_resource "scalr_provider_configuration_default" {
    defaults = {
      id = "env-xxxxxxxxxx/pcfg-mockedvalue1"
    }
  }
}

run "provider_configuration_defaults_uses_internal_provider_configuration_id" {
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
    condition     = output.default_ids["aws_prod_default"] != null
    error_message = "provider_configuration_defaults entry should resolve using this module's internal wiring."
  }

  # Prove the wrapper actually passed scalr_provider_configuration.this["aws_prod"].id through to
  # the default submodule -- not just that some entry landed under the expected key.
  # "pcfg-mockedvalue1" is the mocked scalr_provider_configuration id above; a wrong or unresolved
  # provider_configuration_id would fail this even though the != null check above would still pass.
  assert {
    condition     = output.resolved_defaults["aws_prod_default"].provider_configuration_id == "pcfg-mockedvalue1"
    error_message = "provider_configuration_key \"aws_prod\" should resolve to the provider configuration created by this same module call, via scalr_provider_configuration.this[...].id."
  }

  assert {
    condition     = output.resolved_defaults["aws_prod_default"].provider_configuration_id == scalr_provider_configuration.this["aws_prod"].id
    error_message = "The resolved_defaults output should match the provider configuration actually created for the aws_prod key."
  }
}

run "provider_configuration_defaults_accepts_external_provider_configuration_id" {
  command = plan

  variables {
    provider_configuration_defaults = {
      external = {
        provider_configuration_id = "pcfg-external00000"
        environment_id            = "env-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = output.default_ids["external"] != null
    error_message = "provider_configuration_defaults entry with a literal provider_configuration_id (no corresponding var.provider_configurations entry) should plan successfully."
  }
}
