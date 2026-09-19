mock_provider "scalr" {
  mock_resource "scalr_storage_profile" {
    defaults = {
      id = "sp-abcd1234"
    }
  }
}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    storage_profiles = {
      primary = {
        aws_s3 = {
          audience    = "scalr-storage"
          bucket_name = "my-scalr-state-bucket"
          role_arn    = "arn:aws:iam::123456789012:role/scalr-storage-profile"
        }
      }
    }
  }

  assert {
    condition     = length(scalr_storage_profile.this) == 1
    error_message = "Expected exactly one storage profile to be planned."
  }
}

run "rejects_entry_with_no_backend_set" {
  command = plan

  variables {
    storage_profiles = {
      primary = {}
    }
  }

  expect_failures = [var.storage_profiles]
}

run "rejects_entry_with_two_backends_set" {
  command = plan

  variables {
    storage_profiles = {
      primary = {
        aws_s3 = {
          audience    = "scalr-storage"
          bucket_name = "my-scalr-state-bucket"
          role_arn    = "arn:aws:iam::123456789012:role/scalr-storage-profile"
        }
        azurerm = {
          audience        = "scalr-storage"
          client_id       = "12345678-1234-1234-1234-123456789012"
          container_name  = "my-container"
          storage_account = "my-storage-account"
          tenant_id       = "12345678-1234-1234-1234-123456789012"
        }
      }
    }
  }

  expect_failures = [var.storage_profiles]
}

run "rejects_google_entry_missing_from_google_credentials" {
  command = plan

  variables {
    storage_profiles = {
      primary = {
        google = {
          storage_bucket = "my-scalr-state-bucket"
          project        = "my-gcp-project"
        }
      }
    }
    # google_credentials is intentionally left unset/empty -- no matching key for "primary".
  }

  expect_failures = [scalr_storage_profile.this]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
