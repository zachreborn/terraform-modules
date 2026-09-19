mock_provider "scalr" {
  mock_resource "scalr_workspace_var_set" {
    defaults = {
      id = "ws-xxxxxxxxxx/varset-xxxxxxxxxx"
    }
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    workspace_var_set_links = {
      prod_shared_vars = {
        workspace_id = "ws-xxxxxxxxxx"
        var_set_id   = "varset-xxxxxxxxxx"
      }
    }
  }

  assert {
    condition     = length(scalr_workspace_var_set.this) == 1
    error_message = "Expected exactly one workspace/var set link to be planned."
  }

  assert {
    condition     = scalr_workspace_var_set.this["prod_shared_vars"].workspace_id == "ws-xxxxxxxxxx"
    error_message = "workspace_id should be passed through from var.workspace_var_set_links."
  }

  assert {
    condition     = scalr_workspace_var_set.this["prod_shared_vars"].var_set_id == "varset-xxxxxxxxxx"
    error_message = "var_set_id should be passed through from var.workspace_var_set_links."
  }

  assert {
    condition     = output.ids["prod_shared_vars"] != null
    error_message = "output.ids should expose the mocked link ID."
  }

  assert {
    condition     = output.links["prod_shared_vars"].var_set_id == "varset-xxxxxxxxxx"
    error_message = "output.links should expose the resolved var_set_id for each entry."
  }
}

run "empty_map_plans_with_no_links" {
  command = plan

  assert {
    condition     = length(scalr_workspace_var_set.this) == 0
    error_message = "An unset (default empty) workspace_var_set_links should plan zero links."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
