# Native OpenTofu tests for modules/scalr/integrations/docker (resources, branches, outputs).
# Validation rules are covered in validation.tftest.hcl.
#
# Run offline with:
#   tofu -chdir=modules/scalr/integrations/docker init -backend=false
#   tofu -chdir=modules/scalr/integrations/docker test
#
# All credential-shaped values below are obviously fake fixtures.

mock_provider "scalr" {
  mock_resource "scalr_docker_integration" {
    defaults = {
      id     = "in-mock00000000"
      status = "active"
    }
  }
}

run "valid_baseline_plans" {
  command = plan

  variables {
    docker_integrations = {
      ghcr = {
        name               = "ghcr"
        registry_url       = "https://ghcr.io"
        username           = "my-user"
        export_credentials = true
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      ghcr = "fake-registry-password"
    }
  }

  assert {
    condition     = length(scalr_docker_integration.this) == 1
    error_message = "Expected exactly one Docker integration to be planned."
  }

  assert {
    condition     = scalr_docker_integration.this["ghcr"].name == "ghcr"
    error_message = "name should be passed through to the resource."
  }

  assert {
    condition     = scalr_docker_integration.this["ghcr"].registry_url == "https://ghcr.io"
    error_message = "registry_url should be passed through to the resource."
  }

  assert {
    condition     = scalr_docker_integration.this["ghcr"].username == "my-user"
    error_message = "username should be passed through to the resource."
  }

  assert {
    condition     = scalr_docker_integration.this["ghcr"].export_credentials == true
    error_message = "export_credentials should be passed through to the resource."
  }

  assert {
    condition     = nonsensitive(scalr_docker_integration.this["ghcr"].password) == "fake-registry-password"
    error_message = "password should be looked up from docker_passwords using the entry's key."
  }

  assert {
    condition     = output.ids["ghcr"] == "in-mock00000000"
    error_message = "ids output should map the logical key to the integration ID."
  }

  assert {
    condition     = output.statuses["ghcr"] == "active"
    error_message = "statuses output should map the logical key to the integration status."
  }
}

###########################################################
# Conditional branch coverage: export_credentials default / explicit false
###########################################################

run "export_credentials_defaults_to_false" {
  command = plan

  variables {
    docker_integrations = {
      ghcr = {
        name         = "ghcr"
        registry_url = "https://ghcr.io"
        username     = "my-user"
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      ghcr = "fake-registry-password"
    }
  }

  assert {
    condition     = scalr_docker_integration.this["ghcr"].export_credentials == false
    error_message = "export_credentials should default to false when omitted."
  }
}

run "export_credentials_can_be_set_explicitly_false" {
  command = plan

  variables {
    docker_integrations = {
      ghcr = {
        name               = "ghcr"
        registry_url       = "https://ghcr.io"
        username           = "my-user"
        export_credentials = false
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      ghcr = "fake-registry-password"
    }
  }

  assert {
    condition     = scalr_docker_integration.this["ghcr"].export_credentials == false
    error_message = "An explicit export_credentials = false should be honored."
  }
}

###########################################################
# registry_url shapes accepted by the module
###########################################################

run "registry_url_accepts_port_and_path" {
  command = plan

  variables {
    docker_integrations = {
      private = {
        name         = "private-registry"
        registry_url = "https://registry.example.com:5000/v2/"
        username     = "svc-account"
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      private = "fake-registry-password"
    }
  }

  assert {
    condition     = scalr_docker_integration.this["private"].registry_url == "https://registry.example.com:5000/v2/"
    error_message = "A valid https URL with a port and path should be accepted unchanged."
  }
}

run "same_host_on_different_ports_is_treated_as_distinct" {
  command = plan

  variables {
    docker_integrations = {
      default_port = {
        name         = "registry-default"
        registry_url = "https://registry.example.com"
        username     = "svc-account"
      }
      custom_port = {
        name         = "registry-custom"
        registry_url = "https://registry.example.com:5000"
        username     = "svc-account"
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      default_port = "fake-password-default"
      custom_port  = "fake-password-custom"
    }
  }

  assert {
    condition     = length(scalr_docker_integration.this) == 2
    error_message = "Scalr normalizes the URL to scheme + host + non-default port, so a non-default port is a different registry."
  }
}

###########################################################
# for_each scaling: each entry receives its own password
###########################################################

run "multiple_integrations_each_get_their_own_password" {
  command = plan

  variables {
    docker_integrations = {
      ghcr = {
        name               = "ghcr"
        registry_url       = "https://ghcr.io"
        username           = "gh-user"
        export_credentials = true
      }
      ecr = {
        name         = "ecr"
        registry_url = "https://123456789012.dkr.ecr.us-east-1.amazonaws.com"
        username     = "AWS"
      }
      dockerhub = {
        name         = "dockerhub"
        registry_url = "https://registry-1.docker.io"
        username     = "hub-user"
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      ghcr      = "fake-password-ghcr"
      ecr       = "fake-password-ecr"
      dockerhub = "fake-password-dockerhub"
    }
  }

  assert {
    condition     = length(scalr_docker_integration.this) == 3
    error_message = "Expected one resource instance per docker_integrations entry."
  }

  assert {
    condition = (
      nonsensitive(scalr_docker_integration.this["ghcr"].password) == "fake-password-ghcr" &&
      nonsensitive(scalr_docker_integration.this["ecr"].password) == "fake-password-ecr" &&
      nonsensitive(scalr_docker_integration.this["dockerhub"].password) == "fake-password-dockerhub"
    )
    error_message = "Each integration must receive the password stored under its own key (no cross-wiring)."
  }

  assert {
    condition     = toset(keys(output.ids)) == toset(["ghcr", "ecr", "dockerhub"]) && toset(keys(output.statuses)) == toset(["ghcr", "ecr", "dockerhub"])
    error_message = "ids and statuses outputs should contain one entry per logical key."
  }
}

run "extra_passwords_without_an_integration_are_ignored" {
  command = plan

  variables {
    docker_integrations = {
      ghcr = {
        name         = "ghcr"
        registry_url = "https://ghcr.io"
        username     = "my-user"
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      ghcr   = "fake-registry-password"
      unused = "fake-unused-password"
    }
  }

  assert {
    condition     = length(scalr_docker_integration.this) == 1
    error_message = "A surplus docker_passwords entry must not create an integration."
  }
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_integrations" {
  command = plan

  assert {
    condition     = length(scalr_docker_integration.this) == 0
    error_message = "An empty docker_integrations map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0 && length(output.statuses) == 0
    error_message = "All outputs should be empty when no integrations are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
