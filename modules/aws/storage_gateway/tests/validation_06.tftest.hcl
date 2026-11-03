mock_provider "aws" {
  mock_resource "aws_storagegateway_gateway" {
    defaults = {
      id  = "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-12A3456B"
      arn = "arn:aws:storagegateway:us-east-1:123456789012:gateway/sgw-12A3456B"
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

  # SMB shares default to ActiveDirectory authentication and FSx associations are
  # served over SMB, so both require a domain-joined gateway. Supplied globally here
  # so each run exercises the validation it is named for rather than this precondition.
  smb_active_directory_settings = {
    domain_name = "corp.example.com"
    username    = "svc_join"
    password    = "testpass" # gitleaks:allow
  }
}



run "rejects_smb_file_share_with_no_resolvable_role" {
  command = plan

  variables {
    gateway_type = "FILE_S3"

    s3_smb_file_shares = {
      finance = {
        location_arn = "arn:aws:s3:::corp-gateway-data/finance"
      }
    }
  }

  expect_failures = [aws_storagegateway_smb_file_share.this]
}

run "rejects_nfs_file_share_with_no_resolvable_role" {
  command = plan

  variables {
    gateway_type = "FILE_S3"

    s3_nfs_file_shares = {
      archive = {
        location_arn = "arn:aws:s3:::corp-gateway-data/archive"
        client_list  = ["10.0.0.0/16"]
      }
    }
  }

  expect_failures = [aws_storagegateway_nfs_file_share.this]
}

# The provider declares activation_key and gateway_ip_address ExactlyOneOf, so supplying
# both is as invalid as supplying neither.
run "rejects_supplying_both_activation_key_and_gateway_ip_address" {
  command = plan

  variables {
    activation_key     = "ABCDE-12345-FGHIJ-67890-KLMNO"
    gateway_ip_address = "206.7.1.205"
  }

  expect_failures = [aws_storagegateway_gateway.this]
}

###########################
# gateway_type pairing
###########################

run "rejects_file_system_association_on_an_s3_gateway" {
  command = plan

  variables {
    gateway_type = "FILE_S3"

    file_system_associations = {
      corp = {
        location_arn = "arn:aws:fsx:us-east-1:123456789012:file-system/fs-0123456789abcdef0"
        username     = "svc_gateway"
        password     = "testpass" # gitleaks:allow
      }
    }
  }

  expect_failures = [aws_storagegateway_file_system_association.this]
}

run "rejects_s3_smb_share_on_an_fsx_gateway" {
  command = plan

  variables {
    gateway_type = "FILE_FSX_SMB"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_smb_file_shares = {
      finance = {
        location_arn = "arn:aws:s3:::corp-gateway-data/finance"
      }
    }
  }

  expect_failures = [aws_storagegateway_smb_file_share.this]
}

run "rejects_s3_nfs_share_on_an_fsx_gateway" {
  command = plan

  variables {
    gateway_type = "FILE_FSX_SMB"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_nfs_file_shares = {
      archive = {
        location_arn = "arn:aws:s3:::corp-gateway-data/archive"
        client_list  = ["10.0.0.0/16"]
      }
    }
  }

  expect_failures = [aws_storagegateway_nfs_file_share.this]
}

###########################
# Previously uncovered validation paths
###########################

run "rejects_malformed_file_system_association_audit_destination_arn" {
  command = plan

  variables {
    gateway_type = "FILE_FSX_SMB"

    file_system_associations = {
      corp = {
        location_arn          = "arn:aws:fsx:us-east-1:123456789012:file-system/fs-0123456789abcdef0"
        username              = "svc_gateway"
        password              = "testpass" # gitleaks:allow
        audit_destination_arn = "arn:aws:s3:::not-a-log-group"
      }
    }
  }

  expect_failures = [var.file_system_associations]
}

run "rejects_malformed_nfs_share_location_arn" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_nfs_file_shares = {
      archive = {
        location_arn = "corp-gateway-data"
        client_list  = ["10.0.0.0/16"]
      }
    }
  }

  expect_failures = [var.s3_nfs_file_shares]
}

run "rejects_malformed_nfs_share_role_arn" {
  command = plan

  variables {
    gateway_type = "FILE_S3"

    s3_nfs_file_shares = {
      archive = {
        location_arn = "arn:aws:s3:::corp-gateway-data/archive"
        client_list  = ["10.0.0.0/16"]
        role_arn     = "arn:aws:iam::123456789012:user/somebody"
      }
    }
  }

  expect_failures = [var.s3_nfs_file_shares]
}

run "rejects_a_bare_kms_alias_on_an_nfs_share" {
  command = plan

  variables {
    gateway_type = "FILE_S3"
    role_arn     = "arn:aws:iam::123456789012:role/byo-gateway-role"

    s3_nfs_file_shares = {
      archive = {
        location_arn  = "arn:aws:s3:::corp-gateway-data/archive"
        client_list   = ["10.0.0.0/16"]
        kms_encrypted = true
        kms_key_arn   = "alias/my-share-key"
      }
    }
  }

  expect_failures = [var.s3_nfs_file_shares]
}