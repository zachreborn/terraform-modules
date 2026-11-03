mock_provider "aws" {}

# Scalar type conversion errors (for example visibility = "invalid") occur
# before variable validation; they are not represented as expect_failures.

variables {
  name           = "work"
  create_kms_key = false
}



run "key_deletion_window_in_days_above" {
  command = plan
  variables {
    key_deletion_window_in_days = 31
  }
  expect_failures = [var.key_deletion_window_in_days]
}

run "key_deletion_window_in_days_fractional" {
  command = plan
  variables {
    key_deletion_window_in_days = 7.5
  }
  expect_failures = [var.key_deletion_window_in_days]
}

run "key_deletion_window_in_days_minimum" {
  command = plan
  variables {
    key_deletion_window_in_days = 7
    create_kms_key              = true
    key_policy                  = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
  assert {
    condition     = module.kms[0].deletion_window_in_days == 7
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "key_deletion_window_in_days_maximum" {
  command = plan
  variables {
    key_deletion_window_in_days = 30
    create_kms_key              = true
    key_policy                  = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
  assert {
    condition     = module.kms[0].deletion_window_in_days == 30
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "policy_malformed" {
  command = plan
  variables {
    policy = "not-json"
  }
  expect_failures = [var.policy]
}

run "key_policy_malformed" {
  command = plan
  variables {
    key_policy = "not-json"
  }
  expect_failures = [var.key_policy]
}

run "redrive_policy_malformed" {
  command = plan
  variables {
    redrive_policy = "not-json"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_allow_policy_malformed" {
  command = plan
  variables {
    redrive_allow_policy = "not-json"
  }
  expect_failures = [var.redrive_allow_policy]
}

run "policy_missing_version" {
  command = plan
  variables {
    policy = "{\"Statement\": []}"
  }
  expect_failures = [var.policy]
}

run "policy_wrong_version" {
  command = plan
  variables {
    policy = "{\"Version\": \"2008-10-17\", \"Statement\": []}"
  }
  expect_failures = [var.policy]
}