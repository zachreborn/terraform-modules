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
      path         = "/"
    }
  }

  mock_resource "aws_storagegateway_nfs_file_share" {
    defaults = {
      arn          = "arn:aws:storagegateway:us-east-1:123456789012:share/share-0fedcba9876543210"
      fileshare_id = "share-0fedcba9876543210"
      path         = "/export/share-0fedcba9876543210"
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

  # Without these, the mock provider returns a random string for the policy documents'
  # json attribute, which the aws provider then rejects as "not a JSON object" when it
  # reaches aws_iam_role.assume_role_policy / aws_iam_policy.policy in the child modules.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  # Pinned so the generated KMS key policy is deterministic across runs.
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

run "default_baseline_plans_successfully" {
  command = plan

  assert {
    condition     = length(aws_storagegateway_gateway.this) == 1
    error_message = "Expected the module to create a gateway when gateway_arn is null."
  }

  # FILE_S3 is the default because Amazon FSx File Gateway (FILE_FSX_SMB) is closed to
  # new AWS customers, so defaulting to it would hand new callers an unprovisionable type.
  assert {
    condition     = aws_storagegateway_gateway.this[0].gateway_type == "FILE_S3"
    error_message = "Expected gateway_type to default to FILE_S3."
  }

  assert {
    condition     = aws_storagegateway_gateway.this[0].gateway_timezone == "GMT"
    error_message = "Expected gateway_timezone to default to GMT."
  }

  # Secure-by-default: SMB signing is enforced rather than left to client negotiation,
  # which is what AWS's own ClientSpecified default would do.
  assert {
    condition     = aws_storagegateway_gateway.this[0].smb_security_strategy == "MandatorySigning"
    error_message = "Expected smb_security_strategy to default to MandatorySigning."
  }

  assert {
    condition     = aws_storagegateway_gateway.this[0].tags["Name"] == "corp-file-gateway"
    error_message = "Expected the gateway to carry a Name tag derived from gateway_name."
  }

  # Secure-by-default: gateway health logs go to an encrypted log group without the
  # caller having to opt in.
  assert {
    condition     = length(module.cloudwatch_log_group) == 1
    error_message = "Expected the cloudwatch/log_group child module to be created by default."
  }

  assert {
    condition     = length(module.kms_key) == 1
    error_message = "Expected the kms child module to be created by default."
  }

  assert {
    condition     = aws_storagegateway_gateway.this[0].cloudwatch_log_group_arn == module.cloudwatch_log_group[0].arn
    error_message = "Expected the module-created log group to be wired to the gateway."
  }

  # No IAM role, cache, associations, or shares unless the caller asks for them.
  assert {
    condition     = length(module.iam_role) == 0 && length(module.iam_policy) == 0
    error_message = "Expected no IAM role or policy when create_iam_role is false (the default)."
  }

  assert {
    condition     = length(aws_storagegateway_cache.this) == 0
    error_message = "Expected no cache disks when cache_disk_ids is empty."
  }

  assert {
    condition     = length(aws_storagegateway_file_system_association.this) == 0
    error_message = "Expected no file system associations by default."
  }

  assert {
    condition     = length(aws_storagegateway_smb_file_share.this) == 0 && length(aws_storagegateway_nfs_file_share.this) == 0
    error_message = "Expected no S3 file shares by default."
  }

  # The gateway is created with no maintenance window or domain join unless configured,
  # which lets the service pick its own window.
  assert {
    condition     = length(aws_storagegateway_gateway.this[0].maintenance_start_time) == 0
    error_message = "Expected no maintenance_start_time block when the variable is null."
  }

  assert {
    condition     = length(aws_storagegateway_gateway.this[0].smb_active_directory_settings) == 0
    error_message = "Expected no smb_active_directory_settings block when the variable is null."
  }
}

run "activation_key_satisfies_the_gateway_precondition" {
  command = plan

  variables {
    gateway_ip_address = null
    activation_key     = "ABCDE-12345-FGHIJ-67890-KLMNO"
  }

  assert {
    condition     = aws_storagegateway_gateway.this[0].activation_key == "ABCDE-12345-FGHIJ-67890-KLMNO"
    error_message = "Expected an activation_key alone to satisfy the gateway precondition and flow to the resource."
  }
}

run "byo_cloudwatch_log_group_skips_the_log_group_module" {
  command = plan

  variables {
    cloudwatch_log_group_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/existing/gateway-logs"
  }

  assert {
    condition     = length(module.cloudwatch_log_group) == 0
    error_message = "Expected no cloudwatch/log_group child module when cloudwatch_log_group_arn is supplied."
  }

  # Regression test: create_kms_key defaults to true, so before this was gated on
  # cloudwatch_log_group_arn the module built a customer-managed key and alias that no
  # resource consumed - a billable, unmanaged orphan on the documented BYO-log-group path.
  assert {
    condition     = length(module.kms_key) == 0
    error_message = "Expected no kms child module when the log group is caller-supplied; a key created here would be an orphan."
  }

  assert {
    condition     = output.kms_key_arn == null && output.kms_key_id == null
    error_message = "Expected the KMS outputs to be null when no key is created for a caller-supplied log group."
  }

  assert {
    condition     = aws_storagegateway_gateway.this[0].cloudwatch_log_group_arn == "arn:aws:logs:us-east-1:123456789012:log-group:/existing/gateway-logs"
    error_message = "Expected the caller-supplied log group ARN to be wired to the gateway."
  }
}

run "disabling_the_log_group_skips_both_log_group_and_kms" {
  command = plan

  variables {
    create_cloudwatch_log_group = false
  }

  assert {
    condition     = length(module.cloudwatch_log_group) == 0
    error_message = "Expected no cloudwatch/log_group child module when create_cloudwatch_log_group is false."
  }

  # The KMS key exists only to encrypt the log group, so it must not be created on its own.
  assert {
    condition     = length(module.kms_key) == 0
    error_message = "Expected no kms child module when create_cloudwatch_log_group is false."
  }

  assert {
    condition     = aws_storagegateway_gateway.this[0].cloudwatch_log_group_arn == null
    error_message = "Expected no log group ARN on the gateway when logging is disabled."
  }
}

run "byo_kms_key_skips_the_kms_module" {
  command = plan

  variables {
    create_kms_key = false
    kms_key_id     = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-abcd-1234-abcd-abcd1234abcd"
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "Expected no kms child module when create_kms_key is false."
  }

  assert {
    condition     = length(module.cloudwatch_log_group) == 1
    error_message = "Expected the log group to still be created using the caller-supplied key."
  }
}

run "existing_gateway_arn_skips_gateway_creation" {
  command = plan

  variables {
    gateway_arn        = "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-98F7654E"
    gateway_ip_address = null
  }

  assert {
    condition     = length(aws_storagegateway_gateway.this) == 0
    error_message = "Expected no gateway resource when gateway_arn supplies an externally activated gateway."
  }

  assert {
    condition     = output.gateway_arn == "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-98F7654E"
    error_message = "Expected the caller-supplied gateway ARN to flow through to the gateway_arn output."
  }

  assert {
    condition     = output.gateway_id == "sgw-98F7654E"
    error_message = "Expected gateway_id to be parsed out of the caller-supplied gateway ARN."
  }

  # These attributes only exist on a module-created gateway.
  assert {
    condition     = output.ec2_instance_id == null && output.host_environment == null && output.gateway_network_interface == null
    error_message = "Expected the gateway-instance outputs to be null when the gateway is not created by this module."
  }
}

run "cache_disks_attach_to_the_gateway" {
  command = plan

  variables {
    cache_disk_ids = ["SCSI-0:0", "SCSI-0:1"]
  }

  assert {
    condition     = length(aws_storagegateway_cache.this) == 2
    error_message = "Expected one cache resource per entry in cache_disk_ids."
  }

  assert {
    condition     = aws_storagegateway_cache.this["SCSI-0:0"].gateway_arn == aws_storagegateway_gateway.this[0].arn
    error_message = "Expected cache disks to attach to the gateway created by this module."
  }

  # Set equality, not a subset check: a subset check also passes for an empty output
  # or one that dropped a disk.
  assert {
    condition     = output.cache_disk_ids == toset(["SCSI-0:0", "SCSI-0:1"])
    error_message = "Expected the cache_disk_ids output to list exactly the allocated disk IDs."
  }
}

run "file_system_associations_plan_successfully" {
  command = plan

  variables {
    gateway_type = "FILE_FSX_SMB"

    smb_active_directory_settings = {
      domain_name = "corp.example.com"
      username    = "svc_join"
      password    = "testpass" # gitleaks:allow
    }

    file_system_associations = {
      corp = {
        location_arn          = "arn:aws:fsx:us-east-1:123456789012:file-system/fs-0123456789abcdef0"
        username              = "svc_gateway"
        password              = "testpass" # gitleaks:allow
        audit_destination_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/storagegateway/audit"
        cache_attributes = {
          cache_stale_timeout_in_seconds = 300
        }
      }
    }
  }

  assert {
    condition     = length(aws_storagegateway_file_system_association.this) == 1
    error_message = "Expected one file system association per entry in file_system_associations."
  }

  assert {
    condition     = aws_storagegateway_file_system_association.this["corp"].gateway_arn == aws_storagegateway_gateway.this[0].arn
    error_message = "Expected the association to attach to the gateway created by this module."
  }

  assert {
    condition     = aws_storagegateway_file_system_association.this["corp"].tags["Name"] == "corp"
    error_message = "Expected the association's Name tag to be derived from its map key."
  }

  assert {
    condition     = one(aws_storagegateway_file_system_association.this["corp"].cache_attributes).cache_stale_timeout_in_seconds == 300
    error_message = "Expected the optional cache_attributes block to be emitted when supplied."
  }
}

run "file_system_association_omits_cache_attributes_when_unset" {
  command = plan

  variables {
    gateway_type = "FILE_FSX_SMB"

    smb_active_directory_settings = {
      domain_name = "corp.example.com"
      username    = "svc_join"
      password    = "testpass" # gitleaks:allow
    }

    file_system_associations = {
      corp = {
        location_arn = "arn:aws:fsx:us-east-1:123456789012:file-system/fs-0123456789abcdef0"
        username     = "svc_gateway"
        password     = "testpass" # gitleaks:allow
      }
    }
  }

  assert {
    condition     = length(aws_storagegateway_file_system_association.this["corp"].cache_attributes) == 0
    error_message = "Expected no cache_attributes block when the association does not set one."
  }
}

run "s3_file_shares_use_the_module_created_iam_role" {
  command = plan

  variables {
    gateway_type    = "FILE_S3"
    create_iam_role = true
    s3_bucket_arns  = ["arn:aws:s3:::corp-gateway-data"]

    smb_active_directory_settings = {
      domain_name = "corp.example.com"
      username    = "svc_join"
      password    = "testpass" # gitleaks:allow
    }

    s3_smb_file_shares = {
      finance = {
        location_arn   = "arn:aws:s3:::corp-gateway-data/finance"
        authentication = "ActiveDirectory"
        read_only      = false
        cache_attributes = {
          cache_stale_timeout_in_seconds = 600
        }
      }
    }

    s3_nfs_file_shares = {
      archive = {
        location_arn = "arn:aws:s3:::corp-gateway-data/archive"
        client_list  = ["10.0.0.0/16"]
        squash       = "RootSquash"
        nfs_file_share_defaults = {
          directory_mode = "0777"
          file_mode      = "0666"
          group_id       = 65534
          owner_id       = 65534
        }
      }
    }
  }

  assert {
    condition     = length(module.iam_role) == 1 && length(module.iam_policy) == 1
    error_message = "Expected the iam/role and iam/policy child modules when create_iam_role is true."
  }

  assert {
    condition     = aws_storagegateway_smb_file_share.this["finance"].role_arn == module.iam_role[0].arn
    error_message = "Expected the SMB share to default to the module-created role's ARN."
  }

  assert {
    condition     = aws_storagegateway_nfs_file_share.this["archive"].role_arn == module.iam_role[0].arn
    error_message = "Expected the NFS share to default to the module-created role's ARN."
  }

  assert {
    condition     = aws_storagegateway_smb_file_share.this["finance"].gateway_arn == aws_storagegateway_gateway.this[0].arn
    error_message = "Expected the SMB share to attach to the gateway created by this module."
  }

  assert {
    condition     = aws_storagegateway_nfs_file_share.this["archive"].gateway_arn == aws_storagegateway_gateway.this[0].arn
    error_message = "Expected the NFS share to attach to the gateway created by this module."
  }

  assert {
    condition     = aws_storagegateway_smb_file_share.this["finance"].tags["Name"] == "finance"
    error_message = "Expected the SMB share's Name tag to be derived from its map key."
  }

  assert {
    condition     = aws_storagegateway_nfs_file_share.this["archive"].tags["Name"] == "archive"
    error_message = "Expected the NFS share's Name tag to be derived from its map key."
  }

  assert {
    condition     = one(aws_storagegateway_smb_file_share.this["finance"].cache_attributes).cache_stale_timeout_in_seconds == 600
    error_message = "Expected the SMB share's optional cache_attributes block to be emitted when supplied."
  }

  assert {
    condition     = one(aws_storagegateway_nfs_file_share.this["archive"].nfs_file_share_defaults).directory_mode == "0777"
    error_message = "Expected the NFS share's optional nfs_file_share_defaults block to be emitted when supplied."
  }

  assert {
    condition     = length(aws_storagegateway_nfs_file_share.this["archive"].cache_attributes) == 0
    error_message = "Expected no cache_attributes block on the NFS share, which does not set one."
  }
}

run "per_share_role_arn_overrides_the_module_role" {
  command = plan

  variables {
    gateway_type    = "FILE_S3"
    create_iam_role = true
    s3_bucket_arns  = ["arn:aws:s3:::corp-gateway-data"]

    smb_active_directory_settings = {
      domain_name = "corp.example.com"
      username    = "svc_join"
      password    = "testpass" # gitleaks:allow
    }

    s3_smb_file_shares = {
      finance = {
        location_arn = "arn:aws:s3:::corp-gateway-data/finance"
        role_arn     = "arn:aws:iam::123456789012:role/share-specific"
      }
    }
  }

  assert {
    condition     = aws_storagegateway_smb_file_share.this["finance"].role_arn == "arn:aws:iam::123456789012:role/share-specific"
    error_message = "Expected a share-level role_arn to take precedence over the module-created role."
  }
}

run "module_level_role_arn_suppresses_iam_role_creation" {
  command = plan

  variables {
    gateway_type    = "FILE_S3"
    create_iam_role = true
    role_arn        = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_nfs_file_shares = {
      archive = {
        location_arn = "arn:aws:s3:::corp-gateway-data/archive"
        client_list  = ["10.0.0.0/16"]
      }
    }
  }

  # role_arn always wins, so create_iam_role must be ignored rather than creating an
  # orphaned role alongside the caller's.
  assert {
    condition     = length(module.iam_role) == 0 && length(module.iam_policy) == 0
    error_message = "Expected no IAM role or policy when role_arn is supplied, even with create_iam_role true."
  }

  assert {
    condition     = aws_storagegateway_nfs_file_share.this["archive"].role_arn == "arn:aws:iam::123456789012:role/byo-gateway-role"
    error_message = "Expected the caller-supplied role_arn to be used as the share's default role."
  }
}

run "maintenance_window_and_domain_join_flow_to_the_gateway" {
  command = plan

  variables {
    smb_security_strategy     = "MandatoryEncryption"
    smb_file_share_visibility = true

    maintenance_start_time = {
      hour_of_day    = 3
      minute_of_hour = 30
      day_of_week    = 6
    }

    smb_active_directory_settings = {
      domain_name         = "corp.example.com"
      username            = "svc_join"
      password            = "testpass" # gitleaks:allow
      domain_controllers  = ["10.0.1.10:389"]
      organizational_unit = "OU=Gateways,DC=corp,DC=example,DC=com"
      timeout_in_seconds  = 60
    }
  }

  assert {
    condition     = one(aws_storagegateway_gateway.this[0].maintenance_start_time).hour_of_day == 3
    error_message = "Expected the maintenance_start_time block to be emitted with the supplied hour_of_day."
  }

  # The provider types day_of_week and day_of_month as strings, so the numbers this
  # module accepts are converted on the way in. Asserted as a string to match.
  assert {
    condition     = one(aws_storagegateway_gateway.this[0].maintenance_start_time).day_of_week == "6"
    error_message = "Expected the maintenance_start_time block to carry the supplied day_of_week."
  }

  assert {
    condition     = one(aws_storagegateway_gateway.this[0].smb_active_directory_settings).domain_name == "corp.example.com"
    error_message = "Expected the smb_active_directory_settings block to be emitted with the supplied domain_name."
  }

  assert {
    condition     = one(aws_storagegateway_gateway.this[0].smb_active_directory_settings).organizational_unit == "OU=Gateways,DC=corp,DC=example,DC=com"
    error_message = "Expected the smb_active_directory_settings block to carry the supplied organizational_unit."
  }

  assert {
    condition     = aws_storagegateway_gateway.this[0].smb_security_strategy == "MandatoryEncryption"
    error_message = "Expected smb_security_strategy to flow to the gateway."
  }
}

run "vpc_endpoint_and_timezone_flow_to_the_gateway" {
  command = plan

  variables {
    gateway_vpc_endpoint = "vpce-0123456789abcdef0.storagegateway.us-east-1.vpce.amazonaws.com"
    gateway_timezone     = "GMT-7:00"
  }

  assert {
    condition     = aws_storagegateway_gateway.this[0].gateway_vpc_endpoint == "vpce-0123456789abcdef0.storagegateway.us-east-1.vpce.amazonaws.com"
    error_message = "Expected the VPC endpoint to flow to the gateway."
  }

  assert {
    condition     = aws_storagegateway_gateway.this[0].gateway_timezone == "GMT-7:00"
    error_message = "Expected a caller-supplied gateway_timezone to override the default."
  }
}

# The gateway_type guards are skipped for an adopted gateway, because the module cannot
# read the type of a gateway it did not create.
run "adopted_gateway_skips_the_gateway_type_guards" {
  command = plan

  variables {
    gateway_arn        = "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-98F7654E"
    gateway_ip_address = null
    gateway_type       = "FILE_FSX_SMB"
    role_arn           = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_nfs_file_shares = {
      archive = {
        location_arn = "arn:aws:s3:::corp-gateway-data/archive"
        client_list  = ["10.0.0.0/16"]
      }
    }
  }

  assert {
    condition     = aws_storagegateway_nfs_file_share.this["archive"].gateway_arn == "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-98F7654E"
    error_message = "Expected an S3 share on an adopted gateway to plan even though gateway_type says FILE_FSX_SMB."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that the module's defaults or conditional resource creation has a bug, and fix
# the root cause in main.tf, then re-run `tofu test` until it passes for the right reason.
