mock_provider "scalr" {
  mock_resource "scalr_storage_profile" {
    defaults = {
      id = "sp-abcd1234"
    }
  }
}

run "aws_s3_backend_plans_successfully" {
  command = plan

  variables {
    storage_profiles = {
      primary = {
        default = true
        aws_s3 = {
          audience    = "scalr-storage"
          bucket_name = "my-scalr-state-bucket"
          role_arn    = "arn:aws:iam::123456789012:role/scalr-storage-profile"
          region      = "us-east-1"
        }
      }
    }
  }

  assert {
    condition     = scalr_storage_profile.this["primary"].name == "primary"
    error_message = "An entry with no explicit name should default the storage profile name to its map key."
  }

  assert {
    condition     = scalr_storage_profile.this["primary"].default == true
    error_message = "default should be passed through from var.storage_profiles."
  }

  assert {
    condition     = scalr_storage_profile.this["primary"].aws_s3[0].bucket_name == "my-scalr-state-bucket"
    error_message = "aws_s3.bucket_name should be passed through from var.storage_profiles."
  }

  assert {
    condition     = output.ids["primary"] != null
    error_message = "output.ids should expose the mocked storage profile ID."
  }
}

run "azurerm_backend_plans_successfully" {
  command = plan

  variables {
    storage_profiles = {
      azure_backend = {
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

  assert {
    condition     = scalr_storage_profile.this["azure_backend"].azurerm[0].storage_account == "my-storage-account"
    error_message = "azurerm.storage_account should be passed through from var.storage_profiles."
  }
}

run "google_backend_plans_successfully" {
  command = plan

  variables {
    storage_profiles = {
      gcs_backend = {
        google = {
          storage_bucket = "my-scalr-state-bucket"
          project        = "my-gcp-project"
        }
      }
    }
    google_credentials = {
      gcs_backend = "{\"type\": \"service_account\"}"
    }
    google_encryption_keys = {
      gcs_backend = "S5pst/kWvXUmpaIQ8kSb3mr+h4yrA+Q024mOMMO8Bog="
    }
  }

  assert {
    condition     = scalr_storage_profile.this["gcs_backend"].google[0].storage_bucket == "my-scalr-state-bucket"
    error_message = "google.storage_bucket should be passed through from var.storage_profiles."
  }

  assert {
    condition     = scalr_storage_profile.this["gcs_backend"].google[0].project == "my-gcp-project"
    error_message = "google.project should be passed through from var.storage_profiles."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
