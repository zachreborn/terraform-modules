mock_provider "scalr" {
  mock_resource "scalr_role" {
    defaults = {
      id        = "role-abcd1234"
      is_system = false
    }
  }
}

run "plan_succeeds_with_no_roles" {
  command = plan

  variables {
    roles = {}
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "An empty roles map should plan with zero role resources."
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    roles = {
      writer = {
        permissions = ["*:update", "*:delete", "*:create"]
        description = "Write access to all resources."
      }
    }
  }

  assert {
    condition     = output.ids["writer"] != null
    error_message = "Expected the writer role to be planned and expose an id output."
  }

  assert {
    condition     = output.is_system["writer"] == false
    error_message = "Expected the mocked is_system attribute to be surfaced via the is_system output."
  }

  assert {
    condition     = scalr_role.this["writer"].name == "writer"
    error_message = "An entry with no explicit name should default to its map key."
  }
}

run "plan_succeeds_with_multiple_roles_and_explicit_name" {
  command = plan

  variables {
    roles = {
      writer = {
        name        = "Writer"
        permissions = ["*:update", "*:delete", "*:create"]
      }
      reader = {
        permissions = ["*:read"]
        account_id  = "acc-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(output.ids) == 2
    error_message = "Expected exactly two roles to be planned."
  }

  assert {
    condition     = scalr_role.this["writer"].name == "Writer"
    error_message = "An explicit name should override the map key default."
  }

  assert {
    condition     = scalr_role.this["reader"].account_id == "acc-xxxxxxxxxx"
    error_message = "A per-entry account_id should override var.account_id (which is unset here)."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
