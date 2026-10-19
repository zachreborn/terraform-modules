# Native OpenTofu tests for OCI-sourced modules (scalr_module docker_image / docker_integration_id,
# scalr provider >= 3.20.0) in modules/scalr/module.
#
# The existing main/validation/wiring test files are intentionally left untouched: they prove the
# VCS-only interface stayed backward compatible after vcs_provider_id / vcs_repo became optional.
#
# Run offline with:
#   tofu -chdir=modules/scalr/module init -backend=false
#   tofu -chdir=modules/scalr/module test

mock_provider "scalr" {
  mock_resource "scalr_module" {
    defaults = {
      id          = "mod-xxxxxxxxxx"
      source      = "env-xxxx/aws/network"
      source_type = "docker"
      status      = "active"
    }
  }

  mock_resource "scalr_module_namespace" {
    defaults = {
      id = "modns-mockedvalue1"
    }
  }
}

###########################################################
# OCI-sourced entries
###########################################################

run "oci_entry_plans_without_a_vcs_repo_block" {
  command = plan

  variables {
    modules = {
      network = {
        docker_integration_id = "in-xxxxxxxxxx"
        docker_image          = "my-org/terraform-aws-network"
        module_provider       = "aws"
        name                  = "network"
      }
    }
  }

  assert {
    condition     = length(scalr_module.this) == 1
    error_message = "Expected exactly one OCI-sourced module to be planned."
  }

  assert {
    condition     = scalr_module.this["network"].docker_image == "my-org/terraform-aws-network"
    error_message = "docker_image should be passed through unchanged."
  }

  assert {
    condition     = scalr_module.this["network"].docker_integration_id == "in-xxxxxxxxxx"
    error_message = "docker_integration_id should be passed through unchanged."
  }

  assert {
    condition     = scalr_module.this["network"].name == "network" && scalr_module.this["network"].module_provider == "aws"
    error_message = "name and module_provider should be passed through for OCI-sourced modules."
  }

  assert {
    condition     = scalr_module.this["network"].vcs_provider_id == null
    error_message = "vcs_provider_id must stay null for an OCI-sourced module."
  }

  # The provider documents vcs_repo as conflicting with docker_image, so the dynamic block must
  # render nothing (not an empty block) when vcs_repo is null.
  assert {
    condition     = length(scalr_module.this["network"].vcs_repo) == 0
    error_message = "No vcs_repo block should be rendered for an OCI-sourced module."
  }

  assert {
    condition     = output.ids["network"] != null
    error_message = "ids output should contain the OCI-sourced module."
  }

  assert {
    condition     = output.source_types["network"] == "docker"
    error_message = "source_types output should expose the computed source_type of an OCI-sourced module."
  }
}

run "oci_entry_accepts_registry_host_prefix_and_namespace_key" {
  command = plan

  variables {
    module_namespaces = {
      shared = {
        is_shared = true
      }
    }
    modules = {
      network = {
        docker_integration_id = "in-xxxxxxxxxx"
        docker_image          = "ghcr.io/my-org/terraform-aws-network"
        module_provider       = "aws"
        name                  = "network"
        namespace_key         = "shared"
      }
    }
  }

  assert {
    condition     = scalr_module.this["network"].docker_image == "ghcr.io/my-org/terraform-aws-network"
    error_message = "A registry host prefix in docker_image should be passed through unchanged."
  }

  assert {
    condition     = output.resolved_namespace_ids["network"] == "modns-mockedvalue1"
    error_message = "namespace_key should resolve for OCI-sourced modules exactly as for VCS-sourced ones."
  }
}

run "oci_entry_accepts_literal_namespace_id" {
  command = plan

  variables {
    modules = {
      network = {
        docker_integration_id = "in-xxxxxxxxxx"
        docker_image          = "my-org/terraform-aws-network"
        module_provider       = "aws"
        name                  = "network"
        namespace_id          = "modns-external00000"
      }
    }
  }

  assert {
    condition     = output.resolved_namespace_ids["network"] == "modns-external00000"
    error_message = "A literal namespace_id should be passed through for OCI-sourced modules."
  }
}

###########################################################
# Mixed VCS and OCI entries in one call, and the VCS block still renders
###########################################################

run "vcs_and_oci_entries_coexist_in_one_call" {
  command = plan

  # The mock gives every scalr_module the same source_type, so pin each instance separately to
  # prove the source_types output is keyed per entry.
  override_resource {
    target = scalr_module.this["vpc"]
    values = {
      source_type = "vcs"
    }
  }

  override_resource {
    target = scalr_module.this["network"]
    values = {
      source_type = "docker"
    }
  }

  variables {
    modules = {
      vpc = {
        vcs_provider_id = "vcs-xxxxxxxxxx"
        vcs_repo = {
          identifier = "my-org/terraform-aws-vpc"
          path       = "modules/vpc"
          tag_prefix = "aws/"
        }
      }
      network = {
        docker_integration_id = "in-xxxxxxxxxx"
        docker_image          = "my-org/terraform-aws-network"
        module_provider       = "aws"
        name                  = "network"
      }
    }
  }

  assert {
    condition     = length(scalr_module.this) == 2
    error_message = "Expected one VCS-sourced and one OCI-sourced module."
  }

  assert {
    condition     = length(scalr_module.this["vpc"].vcs_repo) == 1
    error_message = "The VCS-sourced entry should still render exactly one vcs_repo block."
  }

  assert {
    condition     = scalr_module.this["vpc"].vcs_repo[0].identifier == "my-org/terraform-aws-vpc"
    error_message = "vcs_repo.identifier should be passed through."
  }

  assert {
    condition     = scalr_module.this["vpc"].vcs_repo[0].path == "modules/vpc" && scalr_module.this["vpc"].vcs_repo[0].tag_prefix == "aws/"
    error_message = "vcs_repo.path and vcs_repo.tag_prefix should be passed through."
  }

  assert {
    condition     = scalr_module.this["vpc"].docker_image == null && scalr_module.this["vpc"].docker_integration_id == null
    error_message = "docker_image / docker_integration_id must stay null for a VCS-sourced module."
  }

  assert {
    condition     = length(scalr_module.this["network"].vcs_repo) == 0
    error_message = "The OCI-sourced entry should render no vcs_repo block."
  }

  assert {
    condition     = output.source_types["vpc"] == "vcs" && output.source_types["network"] == "docker"
    error_message = "source_types output should be keyed per entry (vcs for the VCS entry, docker for the OCI entry)."
  }

  assert {
    condition     = length(output.ids) == 2 && length(output.sources) == 2 && length(output.statuses) == 2 && length(output.source_types) == 2
    error_message = "All per-module outputs should be keyed by both entries."
  }
}

run "vcs_entry_source_type_output_is_keyed_like_ids" {
  command = plan

  override_resource {
    target = scalr_module.this["vpc"]
    values = {
      source_type = "vcs"
    }
  }

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
    condition     = output.source_types["vpc"] == "vcs"
    error_message = "source_types output should expose the computed source_type of a VCS-sourced module."
  }

  assert {
    condition     = keys(output.source_types) == keys(output.ids)
    error_message = "source_types output should use the same keys as the ids output."
  }
}

run "vcs_entry_with_explicit_name_and_module_provider_still_plans" {
  command = plan

  variables {
    modules = {
      infra = {
        vcs_provider_id = "vcs-xxxxxxxxxx"
        module_provider = "couchbasecapella"
        name            = "infra"
        vcs_repo = {
          identifier = "my-org/repo"
          path       = "example/terraform-couchbase-capella-infra"
        }
      }
    }
  }

  assert {
    condition     = scalr_module.this["infra"].name == "infra" && scalr_module.this["infra"].module_provider == "couchbasecapella"
    error_message = "VCS-sourced entries may still set name and module_provider explicitly."
  }
}

###########################################################
# Validation: source selection (expect_failures)
###########################################################

run "rejects_entry_mixing_vcs_and_oci_sources" {
  command = plan

  variables {
    modules = {
      both = {
        vcs_provider_id       = "vcs-xxxxxxxxxx"
        vcs_repo              = { identifier = "my-org/terraform-aws-network" }
        docker_integration_id = "in-xxxxxxxxxx"
        docker_image          = "my-org/terraform-aws-network"
        module_provider       = "aws"
        name                  = "network"
      }
    }
  }

  expect_failures = [var.modules]
}

run "rejects_vcs_provider_id_combined_with_docker_image" {
  command = plan

  variables {
    modules = {
      mixed = {
        vcs_provider_id       = "vcs-xxxxxxxxxx"
        docker_integration_id = "in-xxxxxxxxxx"
        docker_image          = "my-org/terraform-aws-network"
        module_provider       = "aws"
        name                  = "network"
      }
    }
  }

  expect_failures = [var.modules]
}

run "rejects_vcs_repo_combined_with_docker_integration_id" {
  command = plan

  variables {
    modules = {
      mixed = {
        vcs_repo              = { identifier = "my-org/terraform-aws-network" }
        docker_integration_id = "in-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.modules]
}

run "rejects_entry_without_any_source" {
  command = plan

  variables {
    modules = {
      nothing = {
        module_provider = "aws"
        name            = "network"
      }
    }
  }

  expect_failures = [var.modules]
}

run "rejects_empty_entry" {
  command = plan

  variables {
    modules = {
      nothing = {}
    }
  }

  expect_failures = [var.modules]
}

run "rejects_vcs_provider_id_without_vcs_repo" {
  command = plan

  variables {
    modules = {
      vpc = {
        vcs_provider_id = "vcs-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.modules]
}

run "rejects_vcs_repo_without_vcs_provider_id" {
  command = plan

  variables {
    modules = {
      vpc = {
        vcs_repo = { identifier = "my-org/terraform-aws-vpc" }
      }
    }
  }

  expect_failures = [var.modules]
}

run "rejects_docker_image_without_docker_integration_id" {
  command = plan

  variables {
    modules = {
      network = {
        docker_image    = "my-org/terraform-aws-network"
        module_provider = "aws"
        name            = "network"
      }
    }
  }

  expect_failures = [var.modules]
}

run "rejects_docker_integration_id_without_docker_image" {
  command = plan

  variables {
    modules = {
      network = {
        docker_integration_id = "in-xxxxxxxxxx"
        module_provider       = "aws"
        name                  = "network"
      }
    }
  }

  expect_failures = [var.modules]
}

run "rejects_empty_docker_image" {
  command = plan

  variables {
    modules = {
      network = {
        docker_integration_id = "in-xxxxxxxxxx"
        docker_image          = ""
        module_provider       = "aws"
        name                  = "network"
      }
    }
  }

  expect_failures = [var.modules]
}

###########################################################
# Validation: OCI entries require name and module_provider
###########################################################

run "rejects_oci_entry_without_name_and_module_provider" {
  command = plan

  variables {
    modules = {
      network = {
        docker_integration_id = "in-xxxxxxxxxx"
        docker_image          = "my-org/terraform-aws-network"
      }
    }
  }

  expect_failures = [var.modules]
}

run "rejects_oci_entry_without_name" {
  command = plan

  variables {
    modules = {
      network = {
        docker_integration_id = "in-xxxxxxxxxx"
        docker_image          = "my-org/terraform-aws-network"
        module_provider       = "aws"
      }
    }
  }

  expect_failures = [var.modules]
}

run "rejects_oci_entry_without_module_provider" {
  command = plan

  variables {
    modules = {
      network = {
        docker_integration_id = "in-xxxxxxxxxx"
        docker_image          = "my-org/terraform-aws-network"
        name                  = "network"
      }
    }
  }

  expect_failures = [var.modules]
}

run "rejects_vcs_entry_with_name_but_no_module_provider" {
  command = plan

  variables {
    modules = {
      vpc = {
        vcs_provider_id = "vcs-xxxxxxxxxx"
        name            = "vpc"
        vcs_repo        = { identifier = "my-org/terraform-aws-vpc" }
      }
    }
  }

  expect_failures = [var.modules]
}

run "rejects_vcs_entry_with_module_provider_but_no_name" {
  command = plan

  variables {
    modules = {
      vpc = {
        vcs_provider_id = "vcs-xxxxxxxxxx"
        module_provider = "aws"
        vcs_repo        = { identifier = "my-org/terraform-aws-vpc" }
      }
    }
  }

  expect_failures = [var.modules]
}

###########################################################
# Existing namespace validations still apply to OCI-sourced entries
###########################################################

run "rejects_oci_entry_with_namespace_key_and_environment_id" {
  command = plan

  variables {
    module_namespaces = {
      shared = {}
    }
    modules = {
      network = {
        docker_integration_id = "in-xxxxxxxxxx"
        docker_image          = "my-org/terraform-aws-network"
        module_provider       = "aws"
        name                  = "network"
        namespace_key         = "shared"
        environment_id        = "env-xxxxxxxxxx"
      }
    }
  }

  expect_failures = [var.modules]
}

###########################################################
# for_each branch coverage: empty map (default = {})
###########################################################

run "empty_map_creates_no_modules_and_empty_source_types" {
  command = plan

  assert {
    condition     = length(scalr_module.this) == 0
    error_message = "An empty modules map should create no instances."
  }

  assert {
    condition     = length(output.ids) == 0 && length(output.source_types) == 0
    error_message = "ids and source_types outputs should be empty when no modules are configured."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
