mock_provider "aws" {
  mock_resource "aws_storagegateway_gateway" {
    defaults = {
      id               = "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-12A3456B"
      arn              = "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-12A3456B"
      gateway_id       = "sgw-12A3456B"
      ec2_instance_id  = "i-0123456789abcdef0"
      host_environment = "VMWARE"
      endpoint_type    = "STANDARD"
    }
  }

  mock_resource "aws_storagegateway_file_system_association" {
    defaults = {
      arn = "arn:aws:storagegateway:us-east-1:123456789012:fs-association/fsa-0123456789abcdef0"
    }
  }

  mock_resource "aws_storagegateway_smb_file_share" {
    defaults = {
      arn          = "arn:aws:storagegateway:us-east-1:123456789012:share/share-0123456789abcdef0"
      fileshare_id = "share-0123456789abcdef0"
      path         = "/finance"
    }
  }

  mock_resource "aws_storagegateway_nfs_file_share" {
    defaults = {
      arn          = "arn:aws:storagegateway:us-east-1:123456789012:share/share-0fedcba9876543210"
      fileshare_id = "share-0fedcba9876543210"
      path         = "/export/archive"
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
      id = "alias/storage_gateway-abcd1234"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      id  = "/aws/storagegateway/abcd1234"
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/storagegateway/abcd1234"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn  = "arn:aws:iam::123456789012:role/storage-gateway-s3-abcd1234"
      name = "storage-gateway-s3-abcd1234"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/storage-gateway-s3-abcd1234"
    }
  }

  # See the note in baseline.tftest.hcl: the mock provider's random string for `json`
  # is rejected by the aws provider as "not a JSON object".
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }
}

variables {
  gateway_name       = "corp-file-gateway"
  gateway_ip_address = "10.0.1.50"
}

run "generated_kms_key_flows_to_the_log_group_and_outputs" {
  command = plan

  assert {
    condition     = length(module.kms_key) == 1
    error_message = "Expected the kms child module to be instantiated by default."
  }

  assert {
    condition     = length(module.cloudwatch_log_group) == 1
    error_message = "Expected the cloudwatch/log_group child module to be instantiated by default."
  }

  assert {
    condition     = output.kms_key_arn == module.kms_key[0].arn
    error_message = "Expected the kms_key_arn output to reuse the kms child module's arn output."
  }

  assert {
    condition     = output.kms_key_id == module.kms_key[0].key_id
    error_message = "Expected the kms_key_id output to reuse the kms child module's key_id output."
  }

  assert {
    condition     = output.cloudwatch_log_group_arn == module.cloudwatch_log_group[0].arn
    error_message = "Expected the cloudwatch_log_group_arn output to reuse the log group child module's arn output."
  }
}

run "byo_kms_key_flows_to_the_log_group_without_the_kms_module" {
  command = plan

  variables {
    create_kms_key = false
    kms_key_id     = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-abcd-1234-abcd-abcd1234abcd"
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "Expected no kms child module instance when create_kms_key is false."
  }

  assert {
    condition     = length(module.cloudwatch_log_group) == 1
    error_message = "Expected the log group to still be created when the KMS key is caller-supplied."
  }

  assert {
    condition     = output.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/abcd1234-abcd-1234-abcd-abcd1234abcd"
    error_message = "Expected the caller-supplied kms_key_id to flow through as the kms_key_arn output."
  }

  # kms_key_id reports only a key this module created, so it stays null for a BYO key.
  assert {
    condition     = output.kms_key_id == null
    error_message = "Expected the kms_key_id output to be null when no KMS key is created by this module."
  }
}

run "kms_and_cloudwatch_settings_pass_through_to_child_modules" {
  command = plan

  variables {
    kms_key_deletion_window_in_days = 10
    kms_key_enable_key_rotation     = false
    kms_key_description             = "custom description"
    kms_key_name_prefix             = "custom_prefix"
    cloudwatch_name_prefix          = "/aws/storagegateway/custom_"
    cloudwatch_retention_in_days    = 30
  }

  assert {
    condition     = module.kms_key[0].arn != null
    error_message = "Expected the kms child module to expose a non-null arn under custom settings."
  }

  assert {
    condition     = module.cloudwatch_log_group[0].arn != null
    error_message = "Expected the cloudwatch/log_group child module to expose a non-null arn under custom settings."
  }
}

run "no_log_group_leaves_the_log_group_and_kms_outputs_null" {
  command = plan

  variables {
    create_cloudwatch_log_group = false
  }

  assert {
    condition     = output.cloudwatch_log_group_arn == null
    error_message = "Expected the cloudwatch_log_group_arn output to be null when logging is disabled."
  }

  assert {
    condition     = output.kms_key_arn == null && output.kms_key_id == null
    error_message = "Expected both KMS outputs to be null when no log group (and therefore no key) is created."
  }
}

run "iam_role_and_policy_are_wired_together_and_to_the_outputs" {
  command = plan

  variables {
    gateway_type    = "FILE_S3"
    create_iam_role = true
    s3_bucket_arns  = ["arn:aws:s3:::corp-gateway-data", "arn:aws:s3:::corp-gateway-archive"]
    iam_name_prefix = "corp-gateway-s3-"
  }

  assert {
    condition     = length(module.iam_role) == 1 && length(module.iam_policy) == 1
    error_message = "Expected both the iam/role and iam/policy child modules to be instantiated."
  }

  assert {
    condition     = output.iam_role_arn == module.iam_role[0].arn
    error_message = "Expected the iam_role_arn output to reuse the iam/role child module's arn output."
  }

  assert {
    condition     = output.iam_role_name == module.iam_role[0].name
    error_message = "Expected the iam_role_name output to reuse the iam/role child module's name output."
  }

  assert {
    condition     = output.iam_policy_arn == module.iam_policy[0].arn
    error_message = "Expected the iam_policy_arn output to reuse the iam/policy child module's arn output."
  }
}

run "byo_role_arn_reports_through_iam_role_arn_only" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"
  }

  assert {
    condition     = output.iam_role_arn == "arn:aws:iam::123456789012:role/byo-gateway-role"
    error_message = "Expected the caller-supplied role_arn to flow through as the iam_role_arn output."
  }

  # These two describe resources this module created, so a BYO role leaves them null.
  assert {
    condition     = output.iam_role_name == null && output.iam_policy_arn == null
    error_message = "Expected iam_role_name and iam_policy_arn to be null when the role is caller-supplied."
  }
}

run "no_role_at_all_leaves_every_iam_output_null" {
  command = plan

  assert {
    condition     = output.iam_role_arn == null && output.iam_role_name == null && output.iam_policy_arn == null
    error_message = "Expected every IAM output to be null when no role is created or supplied."
  }
}

run "created_gateway_attributes_flow_to_outputs" {
  command = plan

  assert {
    condition     = output.gateway_arn == "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-12A3456B"
    error_message = "Expected the gateway_arn output to expose the created gateway's arn."
  }

  # For a module-created gateway this comes from the provider's own gateway_id attribute
  # rather than string-splitting the ARN.
  assert {
    condition     = output.gateway_id == "sgw-12A3456B"
    error_message = "Expected the gateway_id output to expose the created gateway's gateway_id attribute."
  }

  assert {
    condition     = output.endpoint_type == "STANDARD"
    error_message = "Expected the endpoint_type output to expose the created gateway's endpoint_type."
  }

  assert {
    condition     = output.ec2_instance_id == "i-0123456789abcdef0"
    error_message = "Expected the ec2_instance_id output to expose the created gateway's ec2_instance_id."
  }

  assert {
    condition     = output.host_environment == "VMWARE"
    error_message = "Expected the host_environment output to expose the created gateway's host_environment."
  }

  assert {
    condition     = output.gateway_network_interface == aws_storagegateway_gateway.this[0].gateway_network_interface
    error_message = "Expected the gateway_network_interface output to expose the created gateway's network interfaces."
  }
}

# Split from the FSx association case below: a single gateway is either FILE_S3 or
# FILE_FSX_SMB, so one run block cannot legitimately exercise both.
run "cache_and_s3_shares_flow_to_their_outputs" {
  command = plan

  variables {
    gateway_type    = "FILE_S3"
    create_iam_role = true
    s3_bucket_arns  = ["arn:aws:s3:::corp-gateway-data"]
    cache_disk_ids  = ["SCSI-0:0"]

    s3_smb_file_shares = {
      finance = {
        location_arn = "arn:aws:s3:::corp-gateway-data/finance"
      }
    }

    s3_nfs_file_shares = {
      archive = {
        location_arn = "arn:aws:s3:::corp-gateway-data/archive"
        client_list  = ["10.0.0.0/16"]
      }
    }
  }

  assert {
    condition     = join(",", output.cache_disk_ids) == "SCSI-0:0"
    error_message = "Expected the cache_disk_ids output to list the disk IDs allocated as cache."
  }

  # Every share output is keyed by the caller's logical name so callers can index them
  # by the same key they supplied.
  assert {
    condition     = output.smb_file_share_arns["finance"] == aws_storagegateway_smb_file_share.this["finance"].arn
    error_message = "Expected the smb_file_share_arns output to expose the SMB share's arn under its map key."
  }

  assert {
    condition     = output.smb_file_share_ids["finance"] == "share-0123456789abcdef0"
    error_message = "Expected the smb_file_share_ids output to expose the SMB share's fileshare_id, not its ARN."
  }

  assert {
    condition     = output.smb_file_share_paths["finance"] == "/finance"
    error_message = "Expected the smb_file_share_paths output to expose the SMB share's path."
  }

  assert {
    condition     = output.nfs_file_share_arns["archive"] == aws_storagegateway_nfs_file_share.this["archive"].arn
    error_message = "Expected the nfs_file_share_arns output to expose the NFS share's arn under its map key."
  }

  assert {
    condition     = output.nfs_file_share_ids["archive"] == "share-0fedcba9876543210"
    error_message = "Expected the nfs_file_share_ids output to expose the NFS share's fileshare_id, not its ARN."
  }

  assert {
    condition     = output.nfs_file_share_paths["archive"] == "/export/archive"
    error_message = "Expected the nfs_file_share_paths output to expose the NFS share's path."
  }
}

run "fsx_association_flows_to_its_output" {
  command = plan

  variables {
    gateway_type = "FILE_FSX_SMB"

    file_system_associations = {
      corp = {
        location_arn = "arn:aws:fsx:us-east-1:123456789012:file-system/fs-0123456789abcdef0"
        username     = "svc_gateway"
        password     = "testpass" # gitleaks:allow
      }
    }
  }

  assert {
    condition     = output.file_system_association_arns["corp"] == aws_storagegateway_file_system_association.this["corp"].arn
    error_message = "Expected the file_system_association_arns output to expose the association's arn under its map key."
  }

  assert {
    condition     = aws_storagegateway_file_system_association.this["corp"].gateway_arn == aws_storagegateway_gateway.this[0].arn
    error_message = "Expected the association to attach to the gateway created by this module."
  }
}

# Adopted-gateway mode is the one place associations and S3 shares can appear together in
# a single call, because the module cannot read the adopted gateway's type and therefore
# skips the pairing guards. This asserts wiring only, not that such a gateway is valid.
run "existing_gateway_arn_flows_to_cache_associations_and_shares" {
  command = plan

  variables {
    gateway_arn        = "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-98F7654E"
    gateway_ip_address = null
    gateway_type       = "FILE_S3"
    role_arn           = "arn:aws:iam::123456789012:role/byo-gateway-role"
    cache_disk_ids     = ["SCSI-0:0"]

    file_system_associations = {
      corp = {
        location_arn = "arn:aws:fsx:us-east-1:123456789012:file-system/fs-0123456789abcdef0"
        username     = "svc_gateway"
        password     = "testpass" # gitleaks:allow
      }
    }

    s3_smb_file_shares = {
      finance = {
        location_arn = "arn:aws:s3:::corp-gateway-data/finance"
      }
    }

    s3_nfs_file_shares = {
      archive = {
        location_arn = "arn:aws:s3:::corp-gateway-data/archive"
        client_list  = ["10.0.0.0/16"]
      }
    }
  }

  # Everything that hangs off the gateway must target the caller's externally activated
  # gateway, since this module creates none in that mode.
  assert {
    condition     = aws_storagegateway_cache.this["SCSI-0:0"].gateway_arn == "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-98F7654E"
    error_message = "Expected cache disks to attach to the caller-supplied gateway ARN."
  }

  assert {
    condition     = aws_storagegateway_file_system_association.this["corp"].gateway_arn == "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-98F7654E"
    error_message = "Expected file system associations to attach to the caller-supplied gateway ARN."
  }

  assert {
    condition     = aws_storagegateway_smb_file_share.this["finance"].gateway_arn == "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-98F7654E"
    error_message = "Expected SMB file shares to attach to the caller-supplied gateway ARN."
  }

  assert {
    condition     = aws_storagegateway_nfs_file_share.this["archive"].gateway_arn == "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-98F7654E"
    error_message = "Expected NFS file shares to attach to the caller-supplied gateway ARN."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that the wiring between this module and its kms / cloudwatch/log_group / iam
# child modules (or the gateway's dependent resources) has a bug, and fix the root cause
# in main.tf, then re-run `tofu test` until it passes for the right reason.
