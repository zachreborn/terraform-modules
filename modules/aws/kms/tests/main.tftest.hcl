mock_provider "aws" {
  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:us-east-1:123456789012:key/mock-key-id"
      key_id = "mock-key-id"
    }
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    name_prefix = "example-key"
  }

  assert {
    condition     = aws_kms_key.this.customer_master_key_spec == "SYMMETRIC_DEFAULT"
    error_message = "customer_master_key_spec should default to SYMMETRIC_DEFAULT."
  }

  assert {
    condition     = aws_kms_key.this.deletion_window_in_days == 30
    error_message = "deletion_window_in_days should default to 30."
  }

  assert {
    condition     = aws_kms_key.this.enable_key_rotation == true
    error_message = "enable_key_rotation should default to true."
  }

  assert {
    condition     = aws_kms_key.this.key_usage == "ENCRYPT_DECRYPT"
    error_message = "key_usage should default to ENCRYPT_DECRYPT."
  }

  assert {
    condition     = aws_kms_key.this.is_enabled == true
    error_message = "is_enabled should default to true."
  }

  assert {
    condition     = aws_kms_key.this.tags["environment"] == "prod"
    error_message = "tags should default to include environment = prod."
  }

  assert {
    condition     = output.arn == "arn:aws:kms:us-east-1:123456789012:key/mock-key-id"
    error_message = "arn output should expose the mocked key ARN."
  }

  assert {
    condition     = output.key_id == "mock-key-id"
    error_message = "key_id output should expose the mocked key id."
  }
}

run "overrides_are_honored" {
  command = plan

  variables {
    name_prefix              = "example-key"
    customer_master_key_spec = "RSA_2048"
    deletion_window_in_days  = 7
    enable_key_rotation      = false
    key_usage                = "SIGN_VERIFY"
    is_enabled               = false
    description              = "Custom key description"
    policy                   = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    tags = {
      team = "platform"
    }
  }

  assert {
    condition     = aws_kms_key.this.customer_master_key_spec == "RSA_2048"
    error_message = "customer_master_key_spec override should be honored."
  }

  assert {
    condition     = aws_kms_key.this.deletion_window_in_days == 7
    error_message = "deletion_window_in_days override should be honored."
  }

  assert {
    condition     = aws_kms_key.this.enable_key_rotation == false
    error_message = "enable_key_rotation override should be honored."
  }

  assert {
    condition     = aws_kms_key.this.is_enabled == false
    error_message = "is_enabled override should be honored."
  }

  assert {
    condition     = aws_kms_key.this.description == "Custom key description"
    error_message = "description override should be honored."
  }

  assert {
    condition     = aws_kms_key.this.tags["team"] == "platform"
    error_message = "Explicit tags override should replace the module default tags map."
  }
}

run "name_prefix_without_alias_prefix_gets_alias_prepended" {
  command = plan

  variables {
    name_prefix = "example-key"
  }

  assert {
    condition     = aws_kms_alias.this.name_prefix == "alias/example-key"
    error_message = "A name_prefix without an alias/ prefix should have alias/ prepended."
  }
}

run "name_prefix_with_alias_prefix_passes_through_unchanged" {
  command = plan

  variables {
    name_prefix = "alias/example-key"
  }

  assert {
    condition     = aws_kms_alias.this.name_prefix == "alias/example-key"
    error_message = "A name_prefix that already starts with alias/ should pass through unchanged, not become alias/alias/example-key."
  }
}

# region is Optional and Computed on both aws_kms_key and aws_kms_alias (AWS provider v6's per-resource
# Region override feature), so the mock provider generates fake data for it when unset -- there is no
# meaningful "defaults to null" case to assert via mocks. The override case below is sufficient to prove
# the module wires var.region through to both resources.
run "region_override_is_honored" {
  command = plan

  variables {
    name_prefix = "example-key"
    region      = "us-west-2"
  }

  assert {
    condition     = aws_kms_key.this.region == "us-west-2"
    error_message = "region override should be passed through to aws_kms_key.this."
  }

  assert {
    condition     = aws_kms_alias.this.region == "us-west-2"
    error_message = "region override should be passed through to aws_kms_alias.this so the alias is created alongside the key."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
