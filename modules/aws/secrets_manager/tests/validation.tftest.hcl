mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    secrets = {
      database_credentials = {
        description = "test secret"
      }
    }
  }

  assert {
    condition     = length(aws_secretsmanager_secret.this) == 1
    error_message = "Expected exactly one secret to be planned."
  }
}

run "rejects_entry_with_both_name_and_name_prefix" {
  command = plan

  variables {
    secrets = {
      database_credentials = {
        name        = "db-creds"
        name_prefix = "db-creds-"
      }
    }
  }

  expect_failures = [var.secrets]
}

run "rejects_entry_with_both_create_kms_key_and_kms_key_id" {
  command = plan

  variables {
    secrets = {
      database_credentials = {
        create_kms_key = true
        kms_key_id     = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-ab12-cd34-ef56-abcdef123456"
      }
    }
  }

  expect_failures = [var.secrets]
}

run "rejects_invalid_recovery_window_in_days" {
  command = plan

  variables {
    secrets = {
      database_credentials = {
        recovery_window_in_days = 5
      }
    }
  }

  expect_failures = [var.secrets]
}

run "rejects_rotation_without_lambda_arn" {
  command = plan

  variables {
    secrets = {
      database_credentials = {
        enable_rotation                   = true
        rotation_automatically_after_days = 30
      }
    }
  }

  expect_failures = [var.secrets]
}

run "rejects_rotation_with_both_schedule_fields" {
  command = plan

  variables {
    secrets = {
      database_credentials = {
        enable_rotation                   = true
        rotation_lambda_arn               = "arn:aws:lambda:us-east-1:123456789012:function:rotate"
        rotation_automatically_after_days = 30
        rotation_schedule_expression      = "rate(30 days)"
      }
    }
  }

  expect_failures = [var.secrets]
}

run "rejects_rotation_with_neither_schedule_field" {
  command = plan

  variables {
    secrets = {
      database_credentials = {
        enable_rotation     = true
        rotation_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:rotate"
      }
    }
  }

  expect_failures = [var.secrets]
}

run "rejects_manage_resource_policy_without_resource_policy" {
  command = plan

  variables {
    secrets = {
      database_credentials = {
        manage_resource_policy = true
      }
    }
  }

  expect_failures = [var.secrets]
}

run "rejects_entry_with_both_policy_and_manage_resource_policy" {
  command = plan

  variables {
    secrets = {
      database_credentials = {
        policy                 = "{}"
        manage_resource_policy = true
        resource_policy        = "{}"
      }
    }
  }

  expect_failures = [var.secrets]
}

run "rejects_secret_values_entry_without_any_value" {
  command = plan

  variables {
    secrets = {
      database_credentials = {}
    }
    secret_values = {
      database_credentials = {}
    }
  }

  expect_failures = [var.secret_values]
}

run "rejects_secret_values_entry_with_two_values" {
  command = plan

  variables {
    secrets = {
      database_credentials = {}
    }
    secret_values = {
      database_credentials = {
        secret_string = "value"
        secret_binary = "dmFsdWU="
      }
    }
  }

  expect_failures = [var.secret_values]
}
