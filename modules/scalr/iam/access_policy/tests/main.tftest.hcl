mock_provider "scalr" {
  mock_resource "scalr_access_policy" {
    defaults = {
      id        = "ap-abcd1234"
      is_system = false
    }
  }
}

run "plan_succeeds_with_no_access_policies" {
  command = plan

  variables {
    access_policies = {}
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "An empty access_policies map should plan with zero access policy resources."
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    access_policies = {
      team_read_all_on_acc_scope = {
        role_ids = ["role-abcd1234"]
        subject = {
          type = "team"
          id   = "team-xxxxxxxxxx"
        }
        scope = {
          type = "account"
          id   = "acc-xxxxxxxxxx"
        }
      }
    }
  }

  assert {
    condition     = output.ids["team_read_all_on_acc_scope"] != null
    error_message = "Expected the access policy to be planned and expose an id output."
  }

  assert {
    condition     = output.is_system["team_read_all_on_acc_scope"] == false
    error_message = "Expected the mocked is_system attribute to be surfaced via the is_system output."
  }

  assert {
    condition     = scalr_access_policy.this["team_read_all_on_acc_scope"].subject[0].type == "team"
    error_message = "The subject block's type should be passed through unchanged."
  }

  assert {
    condition     = scalr_access_policy.this["team_read_all_on_acc_scope"].scope[0].type == "account"
    error_message = "The scope block's type should be passed through unchanged."
  }
}

run "plan_succeeds_with_service_account_subject_and_workspace_scope" {
  command = plan

  variables {
    access_policies = {
      sa_write_on_ws_scope = {
        role_ids = ["role-abcd1234", "role-efgh5678"]
        subject = {
          type = "service_account"
          id   = "sa-xxxxxxxxxx"
        }
        scope = {
          type = "workspace"
          id   = "ws-xxxxxxxxxx"
        }
      }
    }
  }

  assert {
    condition     = length(scalr_access_policy.this["sa_write_on_ws_scope"].role_ids) == 2
    error_message = "Expected both role IDs to be planned."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
