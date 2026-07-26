mock_provider "scalr" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    modules = {
      vpc = {
        vcs_provider_id = "vcs-xxxxxxxxxx"
        vcs_repo = {
          identifier = "my-org/terraform-aws-vpc"
        }
      }
    }
  }

  assert {
    condition     = length(scalr_module.this) == 1
    error_message = "Expected exactly one module to be planned."
  }
}

run "rejects_entry_with_both_namespace_id_and_namespace_key" {
  command = plan

  variables {
    module_namespaces = {
      shared = {}
    }
    modules = {
      vpc = {
        vcs_provider_id = "vcs-xxxxxxxxxx"
        namespace_id    = "modns-xxxxxxxxxx"
        namespace_key   = "shared"
        vcs_repo = {
          identifier = "my-org/terraform-aws-vpc"
        }
      }
    }
  }

  expect_failures = [var.modules]
}

run "rejects_entry_with_unknown_namespace_key" {
  command = plan

  variables {
    modules = {
      vpc = {
        vcs_provider_id = "vcs-xxxxxxxxxx"
        namespace_key   = "does_not_exist"
        vcs_repo = {
          identifier = "my-org/terraform-aws-vpc"
        }
      }
    }
  }

  expect_failures = [var.modules]
}

run "rejects_entry_with_namespace_key_and_environment_id" {
  command = plan

  variables {
    module_namespaces = {
      shared = {}
    }
    modules = {
      vpc = {
        vcs_provider_id = "vcs-xxxxxxxxxx"
        namespace_key   = "shared"
        environment_id  = "env-xxxxxxxxxx"
        vcs_repo = {
          identifier = "my-org/terraform-aws-vpc"
        }
      }
    }
  }

  expect_failures = [var.modules]
}

run "rejects_entry_with_empty_vcs_repo_identifier" {
  command = plan

  variables {
    modules = {
      vpc = {
        vcs_provider_id = "vcs-xxxxxxxxxx"
        vcs_repo = {
          identifier = ""
        }
      }
    }
  }

  expect_failures = [var.modules]
}
