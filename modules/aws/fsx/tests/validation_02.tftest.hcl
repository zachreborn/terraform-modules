mock_provider "aws" {
  mock_resource "aws_fsx_windows_file_system" {
    defaults = {
      id  = "fs-0123456789abcdef0"
      arn = "arn:aws:fsx:us-east-1:123456789012:file-system/fs-0123456789abcdef0"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      id     = "1234abcd-12ab-34cd-56ef-1234567890ab"
      key_id = "1234abcd-12ab-34cd-56ef-1234567890ab"
      arn    = "arn:aws:kms:us-east-1:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    }
  }

  mock_resource "aws_kms_alias" {
    defaults = {
      id = "alias/fsx_windows-abcd1234"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      id  = "/aws/fsx/windows_audit_abcd1234"
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/fsx/windows_audit_abcd1234"
    }
  }
}

variables {
  name       = "corp-file-share"
  subnet_ids = ["subnet-0a1b2c3d"]
}



run "rejects_invalid_kms_key_deletion_window_in_days" {
  command = plan

  variables {
    active_directory_id             = "d-0123456789"
    kms_key_deletion_window_in_days = 6
  }

  expect_failures = [var.kms_key_deletion_window_in_days]
}

run "rejects_invalid_file_access_audit_log_level" {
  command = plan

  variables {
    active_directory_id         = "d-0123456789"
    file_access_audit_log_level = "MAYBE"
  }

  expect_failures = [var.file_access_audit_log_level]
}

run "rejects_invalid_file_share_access_audit_log_level" {
  command = plan

  variables {
    active_directory_id               = "d-0123456789"
    file_share_access_audit_log_level = "MAYBE"
  }

  expect_failures = [var.file_share_access_audit_log_level]
}

run "rejects_invalid_cloudwatch_retention_in_days" {
  command = plan

  variables {
    active_directory_id          = "d-0123456789"
    cloudwatch_retention_in_days = 42
  }

  expect_failures = [var.cloudwatch_retention_in_days]
}

run "rejects_self_managed_ad_with_no_credential_method" {
  command = plan

  variables {
    self_managed_active_directory = {
      dns_ips     = ["10.0.0.111"]
      domain_name = "corp.example.com"
    }
  }

  expect_failures = [var.self_managed_active_directory]
}

run "rejects_self_managed_ad_with_conflicting_credential_methods" {
  command = plan

  variables {
    self_managed_active_directory = {
      dns_ips                            = ["10.0.0.111"]
      domain_name                        = "corp.example.com"
      domain_join_service_account_secret = "arn:aws:secretsmanager:us-east-1:123456789012:secret:fsx-join-abcdef"
      username                           = "FSxServiceAccount"
    }
  }

  expect_failures = [var.self_managed_active_directory]
}

run "rejects_self_managed_ad_with_both_password_and_password_wo" {
  command = plan

  variables {
    self_managed_active_directory = {
      dns_ips     = ["10.0.0.111"]
      domain_name = "corp.example.com"
      username    = "FSxServiceAccount"
      password    = "testpass"  # gitleaks:allow
      password_wo = "testpass2" # gitleaks:allow
    }
  }

  expect_failures = [var.self_managed_active_directory]
}

run "rejects_self_managed_ad_password_wo_without_version" {
  command = plan

  variables {
    self_managed_active_directory = {
      dns_ips     = ["10.0.0.111"]
      domain_name = "corp.example.com"
      username    = "FSxServiceAccount"
      password_wo = "testpass" # gitleaks:allow
    }
  }

  expect_failures = [var.self_managed_active_directory]
}

run "rejects_both_active_directory_options_set" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    self_managed_active_directory = {
      dns_ips     = ["10.0.0.111"]
      domain_name = "corp.example.com"
      username    = "FSxServiceAccount"
      password    = "testpass" # gitleaks:allow
    }
  }

  expect_failures = [aws_fsx_windows_file_system.this]
}

run "rejects_neither_active_directory_option_set" {
  command = plan

  expect_failures = [aws_fsx_windows_file_system.this]
}