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

run "rejects_invalid_ip_group_key_reference" {
  command = plan

  variables {
    directories = {
      corp = {
        directory_id  = "d-1234567890"
        ip_group_keys = ["does_not_exist"]
      }
    }
  }

  expect_failures = [aws_workspaces_directory.this]
}

run "explicit_null_workspace_access_properties_falls_back_to_default" {
  command = plan

  # Terraform replaces an explicit null with the declared default for an optional(type, default)
  # attribute -- identical to omitting it entirely -- so this must not fail and must apply the
  # same secure-by-default workspace_access_properties as omitting it.
  variables {
    directories = {
      corp = {
        directory_id                = "d-1234567890"
        workspace_access_properties = null
      }
    }
  }

  assert {
    condition     = aws_workspaces_directory.this["corp"].workspace_access_properties[0].device_type_web == "DENY"
    error_message = "An explicit null workspace_access_properties should fall back to the secure-by-default value, not crash or bypass it."
  }
}

run "rejects_active_directory_config_for_personal_directory" {
  command = plan

  variables {
    directories = {
      corp = {
        directory_id = "d-1234567890"
        active_directory_config = {
          domain_name                = "example.internal"
          service_account_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:example"
        }
      }
    }
  }

  expect_failures = [var.directories]
}

run "rejects_enabled_saml_without_user_access_url" {
  command = plan

  variables {
    directories = {
      corp = {
        directory_id = "d-1234567890"
        saml_properties = {
          status = "ENABLED"
        }
      }
    }
  }

  expect_failures = [var.directories]
}

run "allows_enabled_saml_with_user_access_url" {
  command = plan

  variables {
    directories = {
      corp = {
        directory_id = "d-1234567890"
        saml_properties = {
          status          = "ENABLED"
          user_access_url = "https://sso.example.com/"
        }
      }
    }
  }

  assert {
    condition     = length(aws_workspaces_directory.this) == 1
    error_message = "Expected exactly one directory to be planned."
  }
}

run "rejects_enabled_cba_without_certificate_authority_arn_and_saml" {
  command = plan

  variables {
    directories = {
      corp = {
        directory_id = "d-1234567890"
        certificate_based_auth_properties = {
          status = "ENABLED"
        }
      }
    }
  }

  expect_failures = [var.directories]
}

run "allows_enabled_cba_with_certificate_authority_arn_and_saml_enabled" {
  command = plan

  variables {
    directories = {
      corp = {
        directory_id = "d-1234567890"
        saml_properties = {
          status          = "ENABLED"
          user_access_url = "https://sso.example.com/"
        }
        certificate_based_auth_properties = {
          status                    = "ENABLED"
          certificate_authority_arn = "arn:aws:acm-pca:us-east-1:123456789012:certificate-authority/example"
        }
      }
    }
  }

  assert {
    condition     = length(aws_workspaces_directory.this) == 1
    error_message = "Expected exactly one directory to be planned."
  }
}

run "resolves_valid_ip_group_key_via_ip_group_id_lookup" {
  command = plan

  variables {
    ip_group_id_lookup = {
      corporate_offices = "wsipg-488lrtl3k"
    }
    directories = {
      corp = {
        directory_id  = "d-1234567890"
        ip_group_keys = ["corporate_offices"]
      }
    }
  }

  assert {
    condition     = contains(aws_workspaces_directory.this["corp"].ip_group_ids, "wsipg-488lrtl3k")
    error_message = "ip_group_keys should resolve to the looked-up IP group ID."
  }
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
