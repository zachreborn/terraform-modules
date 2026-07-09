mock_provider "aws" {}

run "valid_baseline_personal_directory_does_not_fail" {
  command = plan

  variables {
    directories = {
      corp = {
        directory_id = "d-1234567890"
        subnet_ids   = ["subnet-aaaa1111", "subnet-bbbb2222"]
      }
    }
  }

  assert {
    condition     = length(aws_workspaces_directory.this) == 1
    error_message = "Expected exactly one directory to be planned."
  }
}

run "valid_baseline_pools_directory_does_not_fail" {
  command = plan

  variables {
    directories = {
      pool = {
        workspace_type                  = "POOLS"
        subnet_ids                      = ["subnet-aaaa1111", "subnet-bbbb2222"]
        workspace_directory_name        = "Pool directory"
        workspace_directory_description = "WorkSpaces Pools directory"
        user_identity_type              = "CUSTOMER_MANAGED"
        active_directory_config = {
          domain_name                = "example.internal"
          service_account_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:example"
        }
      }
    }
  }

  assert {
    condition     = length(aws_workspaces_directory.this) == 1
    error_message = "Expected exactly one directory to be planned."
  }
}

run "rejects_invalid_workspace_type" {
  command = plan

  variables {
    directories = {
      corp = {
        directory_id   = "d-1234567890"
        workspace_type = "INVALID"
      }
    }
  }

  expect_failures = [var.directories]
}

run "rejects_pools_missing_required_fields" {
  command = plan

  variables {
    directories = {
      pool = {
        workspace_type = "POOLS"
      }
    }
  }

  expect_failures = [var.directories]
}

run "rejects_pools_with_directory_id_set" {
  command = plan

  variables {
    directories = {
      pool = {
        workspace_type                  = "POOLS"
        directory_id                    = "d-1234567890"
        workspace_directory_name        = "Pool directory"
        workspace_directory_description = "WorkSpaces Pools directory"
        user_identity_type              = "CUSTOMER_MANAGED"
      }
    }
  }

  expect_failures = [var.directories]
}

run "rejects_personal_without_directory_id" {
  command = plan

  variables {
    directories = {
      corp = {}
    }
  }

  expect_failures = [var.directories]
}

run "rejects_invalid_user_identity_type" {
  command = plan

  variables {
    directories = {
      pool = {
        workspace_type                  = "POOLS"
        workspace_directory_name        = "Pool directory"
        workspace_directory_description = "WorkSpaces Pools directory"
        user_identity_type              = "INVALID"
      }
    }
  }

  expect_failures = [var.directories]
}

run "rejects_invalid_tenancy" {
  command = plan

  variables {
    directories = {
      corp = {
        directory_id = "d-1234567890"
        tenancy      = "INVALID"
      }
    }
  }

  expect_failures = [var.directories]
}

run "rejects_pools_default_ou_without_active_directory_config" {
  command = plan

  variables {
    directories = {
      pool = {
        workspace_type                  = "POOLS"
        workspace_directory_name        = "Pool directory"
        workspace_directory_description = "WorkSpaces Pools directory"
        user_identity_type              = "CUSTOMER_MANAGED"
        workspace_creation_properties = {
          default_ou = "OU=Pools,DC=example,DC=com"
        }
      }
    }
  }

  expect_failures = [var.directories]
}

run "allows_pools_default_ou_with_active_directory_config" {
  command = plan

  variables {
    directories = {
      pool = {
        workspace_type                  = "POOLS"
        workspace_directory_name        = "Pool directory"
        workspace_directory_description = "WorkSpaces Pools directory"
        user_identity_type              = "CUSTOMER_MANAGED"
        active_directory_config = {
          domain_name                = "example.internal"
          service_account_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:example"
        }
        workspace_creation_properties = {
          default_ou = "OU=Pools,DC=example,DC=com"
        }
      }
    }
  }

  assert {
    condition     = length(aws_workspaces_directory.this) == 1
    error_message = "Expected exactly one directory to be planned."
  }
}
