mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      name = "us-east-1"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      key_id = "mock-kms-key-id"
      arn    = "arn:aws:kms:us-east-1:123456789012:key/mock-kms-key-id"
    }
  }
}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    hosted_zone_id = "Z1234567890EXAMPLE"
    name           = "example-ksk"
  }

  assert {
    condition     = aws_kms_key.dnssec.customer_master_key_spec == "ECC_NIST_P256"
    error_message = "Expected a valid plan with the default customer_master_key_spec."
  }
}

run "rejects_invalid_customer_master_key_spec" {
  command = plan

  variables {
    hosted_zone_id           = "Z1234567890EXAMPLE"
    name                     = "example-ksk"
    customer_master_key_spec = "BOGUS"
  }

  expect_failures = [var.customer_master_key_spec]
}

run "rejects_invalid_key_usage" {
  command = plan

  variables {
    hosted_zone_id = "Z1234567890EXAMPLE"
    name           = "example-ksk"
    key_usage      = "BOGUS"
  }

  expect_failures = [var.key_usage]
}

run "rejects_invalid_status" {
  command = plan

  variables {
    hosted_zone_id = "Z1234567890EXAMPLE"
    name           = "example-ksk"
    status         = "BOGUS"
  }

  expect_failures = [var.status]
}

run "rejects_invalid_signing_status" {
  command = plan

  variables {
    hosted_zone_id = "Z1234567890EXAMPLE"
    name           = "example-ksk"
    signing_status = "BOGUS"
  }

  expect_failures = [var.signing_status]
}
