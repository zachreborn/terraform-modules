mock_provider "scalr" {
  mock_resource "scalr_variable" {
    defaults = {
      id             = "var-abcd1234"
      readable_value = null
    }
  }
}

run "value_and_metadata_wire_through_correctly" {
  command = plan

  variables {
    variables = {
      db_password = {
        key          = "db_password"
        category     = "terraform"
        sensitive    = true
        final        = true
        description  = "The database password"
        workspace_id = "ws-xxxxxxxxxx"
      }
    }
    values = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      db_password = "correct-horse-battery-staple"
    }
  }

  assert {
    condition     = scalr_variable.this["db_password"].key == "db_password"
    error_message = "key should be passed through from var.variables."
  }

  assert {
    condition     = scalr_variable.this["db_password"].sensitive == true
    error_message = "sensitive should be passed through from var.variables."
  }

  assert {
    condition     = scalr_variable.this["db_password"].final == true
    error_message = "final should be passed through from var.variables."
  }

  assert {
    condition     = scalr_variable.this["db_password"].value == "correct-horse-battery-staple"
    error_message = "value should be resolved from var.values by the same map key."
  }

  assert {
    condition     = output.ids["db_password"] != null
    error_message = "output.ids should expose the mocked variable ID."
  }
}

run "value_wo_wires_through_correctly" {
  command = plan

  variables {
    variables = {
      api_token = {
        key              = "api_token"
        category         = "terraform"
        sensitive        = true
        value_wo_version = 1
        workspace_id     = "ws-xxxxxxxxxx"
      }
    }
    values_wo = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      api_token = "ephemeral-token-value"
    }
  }

  # value_wo is a write-only attribute -- OpenTofu/Terraform never exposes its actual value back for
  # inspection (even in a test assert), so the only thing we can verify here is that supplying it via
  # var.values_wo does not error and that the version bump used to signal a change is passed through.
  assert {
    condition     = scalr_variable.this["api_token"].value_wo_version == 1
    error_message = "value_wo_version should be passed through from var.variables."
  }
}

run "default_category_is_terraform" {
  command = plan

  variables {
    variables = {
      simple = {
        key          = "simple"
        workspace_id = "ws-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = scalr_variable.this["simple"].category == "terraform"
    error_message = "category should default to \"terraform\" when unset."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
