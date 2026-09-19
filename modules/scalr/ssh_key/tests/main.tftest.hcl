mock_provider "scalr" {
  mock_resource "scalr_ssh_key" {
    defaults = {
      id = "sshkey-abcd1234"
    }
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    ssh_keys = {
      deploy_key = {
        account_id   = "acc-xxxxxxxxxx"
        environments = ["*"]
      }
      ci_key = {
        name       = "ci-deploy-key"
        account_id = "acc-xxxxxxxxxx"
      }
    }
    private_keys = {
      deploy_key = "-----BEGIN OPENSSH PRIVATE KEY-----\nmock\n-----END OPENSSH PRIVATE KEY-----"
      ci_key     = "-----BEGIN OPENSSH PRIVATE KEY-----\nmock2\n-----END OPENSSH PRIVATE KEY-----"
    }
  }

  assert {
    condition     = length(scalr_ssh_key.this) == 2
    error_message = "Expected exactly two SSH keys to be planned."
  }

  assert {
    condition     = scalr_ssh_key.this["deploy_key"].name == "deploy_key"
    error_message = "An entry with no explicit name should default the SSH key name to its map key."
  }

  assert {
    condition     = scalr_ssh_key.this["ci_key"].name == "ci-deploy-key"
    error_message = "An entry with an explicit name should use that name rather than the map key."
  }

  assert {
    condition     = scalr_ssh_key.this["deploy_key"].account_id == "acc-xxxxxxxxxx"
    error_message = "account_id should be passed through from var.ssh_keys."
  }

  assert {
    condition     = output.ids["deploy_key"] != null
    error_message = "output.ids should expose the mocked SSH key ID."
  }

  assert {
    condition     = output.names["ci_key"] == "ci-deploy-key"
    error_message = "output.names should expose the resolved (post-default) SSH key name."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
