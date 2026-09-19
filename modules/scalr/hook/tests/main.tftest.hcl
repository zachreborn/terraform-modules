# Native OpenTofu tests for modules/scalr/hook
#
# All run blocks use command = plan so no real Scalr credentials or backend are needed.
#
# Note: the published provider docs list `vcs_repo` as optional, but the released provider
# (>= 3.17.0) enforces it as required via a schema validator ("Block vcs_repo must have a
# configuration value as the provider has marked it as required"). This module and its tests
# reflect the verified runtime behavior, not the docs.
#
# Run offline with:
#   tofu -chdir=modules/scalr/hook init -backend=false
#   tofu -chdir=modules/scalr/hook test

mock_provider "scalr" {
  mock_resource "scalr_hook" {
    defaults = {
      id = "hook-xxxxxxxxxx"
    }
  }
}

###########################################################
# Valid baseline / conditional branch: vcs_repo.branch omitted
###########################################################

run "plan_succeeds_without_branch" {
  command = plan

  variables {
    hooks = {
      notify = {
        name            = "notify"
        interpreter     = "bash"
        scriptfile_path = "hooks/notify.sh"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        vcs_repo = {
          identifier = "my-org/my-hooks-repo"
        }
      }
    }
  }

  assert {
    condition     = length(scalr_hook.this) == 1
    error_message = "Expected exactly one hook to be planned."
  }

  assert {
    condition     = output.ids["notify"] != null
    error_message = "ids output should contain the 'notify' key."
  }
}

###########################################################
# Conditional branch: vcs_repo.branch provided
###########################################################

run "plan_succeeds_with_branch" {
  command = plan

  variables {
    hooks = {
      notify = {
        name            = "notify"
        interpreter     = "bash"
        scriptfile_path = "hooks/notify.sh"
        vcs_provider_id = "vcs-xxxxxxxxxx"
        description     = "Notifies on apply."
        vcs_repo = {
          identifier = "my-org/my-hooks-repo"
          branch     = "main"
        }
      }
    }
  }

  assert {
    condition     = scalr_hook.this["notify"].vcs_repo[0].identifier == "my-org/my-hooks-repo"
    error_message = "vcs_repo.identifier should be passed through from the input object."
  }

  assert {
    condition     = output.hooks["notify"].description == "Notifies on apply."
    error_message = "hooks output should expose the description attribute."
  }
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_hooks" {
  command = plan

  # hooks is intentionally left unset; exercises the default = {} branch.

  assert {
    condition     = length(scalr_hook.this) == 0
    error_message = "An empty hooks map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0
    error_message = "ids output should be empty when no hooks are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
