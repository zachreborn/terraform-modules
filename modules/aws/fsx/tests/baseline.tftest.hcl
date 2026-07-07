mock_provider "aws" {
  mock_resource "aws_fsx_windows_file_system" {
    defaults = {
      id                             = "fs-0123456789abcdef0"
      arn                            = "arn:aws:fsx:us-east-1:123456789012:file-system/fs-0123456789abcdef0"
      dns_name                       = "amznfsxabcd1234.corp.example.com"
      preferred_file_server_ip       = "10.0.0.111"
      network_interface_ids          = ["eni-0123456789abcdef0"]
      vpc_id                         = "vpc-0123456789abcdef0"
      owner_id                       = "123456789012"
      remote_administration_endpoint = "amznfsxabcd1234.corp.example.com"
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
      id   = "/aws/fsx/windows_audit_abcd1234"
      arn  = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/fsx/windows_audit_abcd1234"
      name = "/aws/fsx/windows_audit_abcd1234"
    }
  }
}

variables {
  name       = "corp-file-share"
  subnet_ids = ["subnet-0a1b2c3d"]
}

run "self_managed_ad_baseline_plans_successfully" {
  command = plan

  variables {
    self_managed_active_directory = {
      dns_ips     = ["10.0.0.111", "10.0.0.111"]
      domain_name = "corp.example.com"
      username    = "FSxServiceAccount"
      password    = "super-secret-password"
    }
  }

  assert {
    condition     = aws_fsx_windows_file_system.this.id != null
    error_message = "Expected exactly one FSx file system to be planned."
  }

  assert {
    condition     = output.arn != null
    error_message = "Expected the arn output to be set."
  }

  assert {
    condition     = output.kms_key_arn != null
    error_message = "Expected a KMS key to be created and its ARN exposed by default."
  }

  assert {
    condition     = output.audit_log_group_arn != null
    error_message = "Expected audit logging to be enabled and its log group ARN exposed by default."
  }
}

run "managed_ad_baseline_plans_successfully" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
  }

  assert {
    condition     = aws_fsx_windows_file_system.this.id != null
    error_message = "Expected exactly one FSx file system to be planned."
  }
}

run "self_managed_ad_with_domain_join_service_account_secret_plans_successfully" {
  command = plan

  variables {
    self_managed_active_directory = {
      dns_ips                            = ["10.0.0.111"]
      domain_name                        = "corp.example.com"
      domain_join_service_account_secret = "arn:aws:secretsmanager:us-east-1:123456789012:secret:fsx-join-abcdef"
    }
  }

  assert {
    condition     = aws_fsx_windows_file_system.this.id != null
    error_message = "Expected exactly one FSx file system to be planned when using a Secrets Manager-based domain join."
  }
}

run "self_managed_ad_with_password_wo_plans_successfully" {
  command = plan

  variables {
    self_managed_active_directory = {
      dns_ips             = ["10.0.0.111"]
      domain_name         = "corp.example.com"
      username            = "FSxServiceAccount"
      password_wo         = "super-secret-password"
      password_wo_version = 1
    }
  }

  assert {
    condition     = aws_fsx_windows_file_system.this.id != null
    error_message = "Expected exactly one FSx file system to be planned when using a write-only password."
  }
}

run "byo_kms_key_skips_kms_module" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    create_kms_key      = false
    kms_key_id          = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-abcd-1234-abcd-abcd1234abcd"
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "Expected no KMS key module instance when create_kms_key is false."
  }

  assert {
    condition     = output.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/abcd1234-abcd-1234-abcd-abcd1234abcd"
    error_message = "Expected kms_key_arn output to equal the caller-supplied kms_key_id."
  }

  assert {
    condition     = output.kms_key_id == null
    error_message = "Expected kms_key_id output to be null when a caller-supplied key is used."
  }
}

run "disabled_audit_logs_skips_log_group_module" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    enable_audit_logs   = false
  }

  assert {
    condition     = length(module.audit_log_group) == 0
    error_message = "Expected no CloudWatch log group module instance when enable_audit_logs is false."
  }

  assert {
    condition     = output.audit_log_group_arn == null
    error_message = "Expected audit_log_group_arn output to be null when audit logging is disabled."
  }
}

run "user_provisioned_disk_iops_plans_successfully" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    disk_iops_configuration = {
      mode = "USER_PROVISIONED"
      iops = 96
    }
  }

  assert {
    condition     = aws_fsx_windows_file_system.this.id != null
    error_message = "Expected exactly one FSx file system to be planned with user-provisioned IOPS."
  }
}

run "multi_az_baseline_plans_successfully" {
  command = plan

  variables {
    active_directory_id = "d-0123456789"
    deployment_type     = "MULTI_AZ_1"
    subnet_ids          = ["subnet-0a1b2c3d", "subnet-4e5f6g7h"]
    preferred_subnet_id = "subnet-0a1b2c3d"
  }

  assert {
    condition     = aws_fsx_windows_file_system.this.id != null
    error_message = "Expected exactly one FSx file system to be planned for a MULTI_AZ_1 deployment."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that the module code has a bug and fix the root cause in main.tf / variables.tf /
# outputs.tf, then re-run `tofu test` until it passes for the right reason.
