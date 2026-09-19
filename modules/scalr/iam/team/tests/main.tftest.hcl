mock_provider "scalr" {
  mock_resource "scalr_iam_team" {
    defaults = {
      id = "team-abcd1234"
    }
  }
}

run "plan_succeeds_with_no_teams" {
  command = plan

  variables {
    teams = {}
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "An empty teams map should plan with zero team resources."
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    teams = {
      dev = {
        description = "Developers"
        users       = ["user-xxxxxxxxxx", "user-yyyyyyyyyy"]
      }
    }
  }

  assert {
    condition     = output.ids["dev"] != null
    error_message = "Expected the dev team to be planned and expose an id output."
  }

  assert {
    condition     = scalr_iam_team.this["dev"].name == "dev"
    error_message = "An entry with no explicit name should default to its map key."
  }
}

run "plan_succeeds_with_explicit_name_and_deprecated_identity_provider_id" {
  command = plan

  variables {
    teams = {
      dev = {
        name                 = "Development"
        identity_provider_id = "idp-xxxxxxxxxx"
        account_id           = "acc-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = scalr_iam_team.this["dev"].name == "Development"
    error_message = "An explicit name should override the map key default."
  }

  assert {
    condition     = scalr_iam_team.this["dev"].identity_provider_id == "idp-xxxxxxxxxx"
    error_message = "The deprecated identity_provider_id attribute should still pass through."
  }

  assert {
    condition     = scalr_iam_team.this["dev"].account_id == "acc-xxxxxxxxxx"
    error_message = "A per-entry account_id should override var.account_id (which is unset here)."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
