# Native OpenTofu validation tests for modules/scalr/integrations/docker.
# One `expect_failures` run per distinct way each validation block can fail.
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

###########################################################
# docker_integrations: name and username
###########################################################

run "rejects_blank_name" {
  command = plan

  variables {
    docker_integrations = {
      ghcr = {
        name         = "  "
        registry_url = "https://ghcr.io"
        username     = "my-user"
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      ghcr = "fake-registry-password"
    }
  }

  expect_failures = [var.docker_integrations]
}

run "rejects_blank_username" {
  command = plan

  variables {
    docker_integrations = {
      ghcr = {
        name         = "ghcr"
        registry_url = "https://ghcr.io"
        username     = ""
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      ghcr = "fake-registry-password"
    }
  }

  expect_failures = [var.docker_integrations]
}

###########################################################
# docker_integrations: registry_url
###########################################################

run "rejects_http_registry_url" {
  command = plan

  variables {
    docker_integrations = {
      ghcr = {
        name         = "ghcr"
        registry_url = "http://ghcr.io"
        username     = "my-user"
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      ghcr = "fake-registry-password"
    }
  }

  expect_failures = [var.docker_integrations]
}

run "rejects_registry_url_without_scheme" {
  command = plan

  variables {
    docker_integrations = {
      ghcr = {
        name         = "ghcr"
        registry_url = "ghcr.io"
        username     = "my-user"
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      ghcr = "fake-registry-password"
    }
  }

  expect_failures = [var.docker_integrations]
}

run "rejects_registry_url_without_host" {
  command = plan

  variables {
    docker_integrations = {
      ghcr = {
        name         = "ghcr"
        registry_url = "https://"
        username     = "my-user"
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      ghcr = "fake-registry-password"
    }
  }

  expect_failures = [var.docker_integrations]
}

run "rejects_registry_url_with_embedded_credentials" {
  command = plan

  variables {
    docker_integrations = {
      ghcr = {
        name         = "ghcr"
        registry_url = "https://my-user:fake-token@ghcr.io"
        username     = "my-user"
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      ghcr = "fake-registry-password"
    }
  }

  expect_failures = [var.docker_integrations]
}

###########################################################
# docker_integrations: one integration per registry host
###########################################################

run "rejects_duplicate_registry_host" {
  command = plan

  variables {
    docker_integrations = {
      first = {
        name         = "ghcr-one"
        registry_url = "https://ghcr.io"
        username     = "user-one"
      }
      second = {
        name         = "ghcr-two"
        registry_url = "https://ghcr.io/some/path"
        username     = "user-two"
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      first  = "fake-password-one"
      second = "fake-password-two"
    }
  }

  expect_failures = [var.docker_integrations]
}

run "rejects_duplicate_registry_host_differing_only_by_case" {
  command = plan

  variables {
    docker_integrations = {
      first = {
        name         = "ghcr-one"
        registry_url = "https://ghcr.io"
        username     = "user-one"
      }
      second = {
        name         = "ghcr-two"
        registry_url = "https://GHCR.IO"
        username     = "user-two"
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      first  = "fake-password-one"
      second = "fake-password-two"
    }
  }

  expect_failures = [var.docker_integrations]
}

run "rejects_duplicate_registry_host_differing_only_by_default_port" {
  command = plan

  variables {
    docker_integrations = {
      first = {
        name         = "ghcr-one"
        registry_url = "https://ghcr.io"
        username     = "user-one"
      }
      second = {
        name         = "ghcr-two"
        registry_url = "https://ghcr.io:443"
        username     = "user-two"
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      first  = "fake-password-one"
      second = "fake-password-two"
    }
  }

  expect_failures = [var.docker_integrations]
}

###########################################################
# docker_passwords: coverage and content
###########################################################

run "rejects_integration_without_matching_password" {
  command = plan

  variables {
    docker_integrations = {
      ghcr = {
        name         = "ghcr"
        registry_url = "https://ghcr.io"
        username     = "my-user"
      }
      ecr = {
        name         = "ecr"
        registry_url = "https://123456789012.dkr.ecr.us-east-1.amazonaws.com"
        username     = "AWS"
      }
    }
    docker_passwords = {
      # checkov:skip=CKV_SECRET_6:Mock literal for an offline unit test, not a real secret.
      ghcr = "fake-registry-password"
    }
  }

  expect_failures = [var.docker_passwords]
}

run "rejects_integration_when_password_map_is_empty" {
  command = plan

  variables {
    docker_integrations = {
      ghcr = {
        name         = "ghcr"
        registry_url = "https://ghcr.io"
        username     = "my-user"
      }
    }
    docker_passwords = {}
  }

  expect_failures = [var.docker_passwords]
}

run "rejects_empty_password" {
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
      ghcr = ""
    }
  }

  expect_failures = [var.docker_passwords]
}

run "rejects_whitespace_only_password" {
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
      ghcr = "   "
    }
  }

  expect_failures = [var.docker_passwords]
}

run "rejects_null_password" {
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
      ghcr = null
    }
  }

  expect_failures = [var.docker_passwords]
}

# Do NOT delete, skip, or loosen an `expect_failures` case just to make `tofu test` pass. A
# validation test that unexpectedly fails means either the `validation {}` block in variables.tf
# has a bug or the test's inputs are wrong -- find and fix the root cause, then re-run
# `tofu test` until it passes for the right reason.
