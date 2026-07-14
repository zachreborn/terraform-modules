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

  mock_resource "aws_kms_alias" {
    defaults = {
      arn = "arn:aws:kms:us-east-1:123456789012:alias/dnssec_mock"
    }
  }

  mock_resource "aws_route53_key_signing_key" {
    defaults = {
      digest_algorithm_mnemonic  = "SHA-256"
      digest_algorithm_type      = 2
      digest_value               = "mockdigestvalue"
      dnskey_record              = "257 3 13 mockdnskey=="
      ds_record                  = "12345 13 2 mockdsrecord"
      flag                       = 257
      key_tag                    = 12345
      public_key                 = "mockpublickey=="
      signing_algorithm_mnemonic = "ECDSAP256SHA256"
      signing_algorithm_type     = 13
    }
  }

  mock_resource "aws_route53_hosted_zone_dnssec" {
    defaults = {
      id = "Z1234567890EXAMPLE"
    }
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    hosted_zone_id = "Z1234567890EXAMPLE"
    name           = "example-ksk"
  }

  assert {
    condition     = aws_route53_key_signing_key.dnssec.hosted_zone_id == "Z1234567890EXAMPLE"
    error_message = "hosted_zone_id should pass through unchanged."
  }

  assert {
    condition     = aws_route53_key_signing_key.dnssec.name == "example-ksk"
    error_message = "name should pass through unchanged."
  }

  assert {
    condition     = aws_route53_hosted_zone_dnssec.dnssec.hosted_zone_id == "Z1234567890EXAMPLE"
    error_message = "aws_route53_hosted_zone_dnssec should be wired to the signing key's hosted_zone_id."
  }
}

run "kms_key_defaults_are_applied" {
  command = plan

  variables {
    hosted_zone_id = "Z1234567890EXAMPLE"
    name           = "example-ksk"
  }

  assert {
    condition     = aws_kms_key.dnssec.customer_master_key_spec == "ECC_NIST_P256"
    error_message = "customer_master_key_spec should default to ECC_NIST_P256."
  }

  assert {
    condition     = aws_kms_key.dnssec.deletion_window_in_days == 7
    error_message = "deletion_window_in_days should default to 7."
  }

  assert {
    condition     = aws_kms_key.dnssec.key_usage == "SIGN_VERIFY"
    error_message = "key_usage should default to SIGN_VERIFY."
  }

  assert {
    condition     = aws_kms_key.dnssec.enable_key_rotation == false
    error_message = "enable_key_rotation should default to false."
  }

  assert {
    condition     = aws_kms_key.dnssec.is_enabled == true
    error_message = "is_enabled should default to true."
  }

  assert {
    condition     = aws_kms_key.dnssec.tags["Name"] == "example-ksk"
    error_message = "KMS key tags should include a Name tag derived from var.name."
  }
}

run "status_and_signing_status_overrides_are_honored" {
  command = plan

  variables {
    hosted_zone_id = "Z1234567890EXAMPLE"
    name           = "example-ksk"
    status         = "INACTIVE"
    signing_status = "NOT_SIGNING"
  }

  assert {
    condition     = aws_route53_key_signing_key.dnssec.status == "INACTIVE"
    error_message = "status override should be honored."
  }

  assert {
    condition     = aws_route53_hosted_zone_dnssec.dnssec.signing_status == "NOT_SIGNING"
    error_message = "signing_status override should be honored."
  }
}

run "kms_alias_name_prefix_defaults_and_overrides" {
  command = plan

  variables {
    hosted_zone_id = "Z1234567890EXAMPLE"
    name           = "example-ksk"
    name_prefix    = "alias/custom_"
  }

  assert {
    condition     = aws_kms_alias.dnssec.name_prefix == "alias/custom_"
    error_message = "name_prefix override should be honored."
  }
}

run "outputs_expose_signing_key_attributes" {
  command = plan

  variables {
    hosted_zone_id = "Z1234567890EXAMPLE"
    name           = "example-ksk"
  }

  assert {
    condition     = output.digest_algorithm_mnemonic == "SHA-256"
    error_message = "digest_algorithm_mnemonic output should equal the mocked value."
  }

  assert {
    condition     = output.digest_algorithm_type == 2
    error_message = "digest_algorithm_type output should equal the mocked value."
  }

  assert {
    condition     = output.digest_value == "mockdigestvalue"
    error_message = "digest_value output should equal the mocked value."
  }

  assert {
    condition     = output.dnskey_record == "257 3 13 mockdnskey=="
    error_message = "dnskey_record output should equal the mocked value."
  }

  assert {
    condition     = output.ds_record == "12345 13 2 mockdsrecord"
    error_message = "ds_record output should equal the mocked value."
  }

  assert {
    condition     = output.flag == 257
    error_message = "flag output should equal the mocked value."
  }

  assert {
    condition     = output.key_tag == 12345
    error_message = "key_tag output should equal the mocked value."
  }

  assert {
    condition     = output.public_key == "mockpublickey=="
    error_message = "public_key output should equal the mocked value."
  }

  assert {
    condition     = output.signing_algorithm_mnemonic == "ECDSAP256SHA256"
    error_message = "signing_algorithm_mnemonic output should equal the mocked value."
  }

  assert {
    condition     = output.signing_algorithm_type == 13
    error_message = "signing_algorithm_type output should equal the mocked value."
  }
}
