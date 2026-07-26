# Validation coverage for every `validation {}` block declared in variables.tf.
# Each variable-level validation is exercised with one valid baseline and one
# expect_failures case. These runs only need to reach the variable-validation
# phase, so `scalr_config` is kept minimal and vcs_repo-free where possible.

mock_provider "scalr" {}

# aws_provider_config must be a non-null (even empty) map: main.tf's existing
# scalr_provider_configuration.aws resource sets `for_each = local.aws_provider_config`
# with no null-guard, so an unset aws_provider_config would error on `for_each`
# before any variable validation runs. That resource block is out of scope for
# this change, so every run below supplies an empty map instead.
variables {
  scalr_config = <<-YAML
    ---
    environment-1:
      workspaces:
        workspace-1:
          vcs_repo: null
  YAML

  aws_provider_config = "{}"
}

run "valid_baseline_does_not_fail" {
  command = plan

  assert {
    condition     = length(scalr_environment.this) == 1
    error_message = "Expected exactly one environment to be planned."
  }
}

###########################
# vcs_provider_vcs_type
###########################
run "rejects_invalid_vcs_provider_vcs_type" {
  command = plan

  variables {
    vcs_provider_vcs_type = "not-a-real-vcs-type"
  }

  expect_failures = [var.vcs_provider_vcs_type]
}

###########################
# aws_account_type
###########################
run "rejects_invalid_aws_account_type" {
  command = plan

  variables {
    aws_account_type = "not-a-real-account-type"
  }

  expect_failures = [var.aws_account_type]
}

###########################
# aws_credentials_type
###########################
run "rejects_invalid_aws_credentials_type" {
  command = plan

  variables {
    aws_credentials_type = "not-a-real-credentials-type"
  }

  expect_failures = [var.aws_credentials_type]
}

###########################
# aws_trusted_entity_type
###########################
run "rejects_invalid_aws_trusted_entity_type" {
  command = plan

  variables {
    aws_trusted_entity_type = "not-a-real-trusted-entity-type"
  }

  expect_failures = [var.aws_trusted_entity_type]
}

###########################
# workspace_auto_queue_runs
###########################
run "rejects_invalid_workspace_auto_queue_runs" {
  command = plan

  variables {
    workspace_auto_queue_runs = "not-a-real-value"
  }

  expect_failures = [var.workspace_auto_queue_runs]
}

###########################
# workspace_execution_mode
###########################
run "rejects_invalid_workspace_execution_mode" {
  command = plan

  variables {
    workspace_execution_mode = "not-a-real-mode"
  }

  expect_failures = [var.workspace_execution_mode]
}

###########################
# workspace_iac_platform
###########################
run "rejects_invalid_workspace_iac_platform" {
  command = plan

  variables {
    workspace_iac_platform = "not-a-real-platform"
  }

  expect_failures = [var.workspace_iac_platform]
}

###########################
# workspace_type
###########################
run "rejects_invalid_workspace_type" {
  command = plan

  variables {
    workspace_type = "not-a-real-type"
  }

  expect_failures = [var.workspace_type]
}

###########################
# azurerm_auth_type
###########################
run "rejects_invalid_azurerm_auth_type" {
  command = plan

  variables {
    azurerm_auth_type = "not-a-real-auth-type"
  }

  expect_failures = [var.azurerm_auth_type]
}

###########################
# google_auth_type
###########################
run "rejects_invalid_google_auth_type" {
  command = plan

  variables {
    google_auth_type = "not-a-real-auth-type"
  }

  expect_failures = [var.google_auth_type]
}

###########################
# google_default_labels_strategy
###########################
run "rejects_invalid_google_default_labels_strategy" {
  command = plan

  variables {
    google_default_labels_strategy = "not-a-real-strategy"
  }

  expect_failures = [var.google_default_labels_strategy]
}

run "accepts_null_google_default_labels_strategy" {
  command = plan

  variables {
    google_default_labels_strategy = null
  }

  assert {
    condition     = var.google_default_labels_strategy == null
    error_message = "google_default_labels_strategy should accept a null value (provider default)."
  }
}
