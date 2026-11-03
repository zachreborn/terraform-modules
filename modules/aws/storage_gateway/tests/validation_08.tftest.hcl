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



run "rejects_active_directory_smb_share_without_domain_join" {
  command = plan

  variables {
    gateway_type                  = "FILE_S3"
    role_arn                      = "arn:aws:iam::123456789012:role/byo-gateway-role"
    smb_active_directory_settings = null

    s3_smb_file_shares = {
      finance = {
        location_arn = "arn:aws:s3:::corp-gateway-data/finance"
      }
    }
  }

  expect_failures = [aws_storagegateway_smb_file_share.this]
}

# GuestAccess does not need a domain join, so the same share planning without AD
# settings proves the precondition is scoped to ActiveDirectory only.
run "accepts_a_guest_access_smb_share_without_domain_join" {
  command = plan

  variables {
    gateway_type                  = "FILE_S3"
    role_arn                      = "arn:aws:iam::123456789012:role/byo-gateway-role"
    smb_active_directory_settings = null

    s3_smb_file_shares = {
      guest = {
        location_arn   = "arn:aws:s3:::corp-gateway-data/guest"
        authentication = "GuestAccess"
      }
    }
  }

  assert {
    condition     = aws_storagegateway_smb_file_share.this["guest"].authentication == "GuestAccess"
    error_message = "Expected a GuestAccess share to plan without smb_active_directory_settings."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that a validation or precondition in the module is wrong, and fix the root cause
# in variables.tf / main.tf, then re-run `tofu test` until it passes for the right reason.
