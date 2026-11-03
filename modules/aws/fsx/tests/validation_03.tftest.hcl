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



run "rejects_byo_kms_key_without_kms_key_id" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    create_kms_key      = false
  }

  expect_failures = [aws_fsx_windows_file_system.this]
}

run "rejects_hdd_storage_below_minimum_capacity" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    storage_type        = "HDD"
    storage_capacity    = 1000
    deployment_type     = "SINGLE_AZ_2"
  }

  expect_failures = [aws_fsx_windows_file_system.this]
}

run "rejects_multi_az_with_single_subnet" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    deployment_type     = "MULTI_AZ_1"
    preferred_subnet_id = "subnet-0a1b2c3d"
  }

  expect_failures = [aws_fsx_windows_file_system.this]
}

run "rejects_single_az_with_two_subnets" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    subnet_ids          = ["subnet-0a1b2c3d", "subnet-4e5f6g7h"]
  }

  expect_failures = [aws_fsx_windows_file_system.this]
}

# Do NOT delete, skip, or loosen an expect_failures case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# validation {} / precondition {} block in variables.tf / main.tf has a bug, or the test's
# inputs are wrong -- find and fix the root cause, then re-run `tofu test` until it passes
# for the right reason.
