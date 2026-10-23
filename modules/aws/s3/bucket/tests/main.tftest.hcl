mock_provider "aws" {
  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:us-west-2:123456789012:key/module-key-id"
      key_id = "module-key-id"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

# kms_master_key_id is Optional and Computed on the provider side, so the mock provider generates fake
# data for it when unset -- there is no meaningful "defaults to null" case to assert via mocks. The
# baseline asserts no module key is created; the runs below prove each key source is wired through.
run "defaults_create_no_module_key" {
  command = plan

  variables {
    bucket_prefix = "example-"
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms"
    error_message = "sse_algorithm should default to aws:kms."
  }

  assert {
    condition     = length(aws_kms_key.s3) == 0
    error_message = "No module KMS key should be created by default."
  }
}

run "external_kms_key_is_used" {
  command = plan

  variables {
    bucket_prefix     = "example-"
    kms_master_key_id = "arn:aws:kms:us-west-2:123456789012:key/external-key-id"
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default[0].kms_master_key_id == "arn:aws:kms:us-west-2:123456789012:key/external-key-id"
    error_message = "kms_master_key_id should be passed through to the bucket's default encryption."
  }

  assert {
    condition     = length(aws_kms_key.s3) == 0
    error_message = "No module KMS key should be created when an external key is supplied."
  }
}

run "module_kms_key_creates_per_bucket_key" {
  command = plan

  variables {
    bucket_prefix  = "example-"
    enable_kms_key = true
  }

  assert {
    condition     = length(aws_kms_key.s3) == 1
    error_message = "enable_kms_key = true should create one module KMS key."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default[0].kms_master_key_id == "arn:aws:kms:us-west-2:123456789012:key/module-key-id"
    error_message = "enable_kms_key = true should encrypt the bucket with the module-created key."
  }
}

run "rejects_both_key_sources" {
  command = plan

  variables {
    bucket_prefix     = "example-"
    enable_kms_key    = true
    kms_master_key_id = "arn:aws:kms:us-west-2:123456789012:key/external-key-id"
  }

  expect_failures = [var.kms_master_key_id]
}

run "rejects_external_key_with_aes256" {
  command = plan

  variables {
    bucket_prefix     = "example-"
    sse_algorithm     = "AES256"
    kms_master_key_id = "arn:aws:kms:us-west-2:123456789012:key/external-key-id"
  }

  expect_failures = [var.kms_master_key_id]
}

run "rejects_empty_external_key" {
  command = plan

  variables {
    bucket_prefix     = "example-"
    kms_master_key_id = "  "
  }

  expect_failures = [var.kms_master_key_id]
}

run "accepts_external_key_with_dsse" {
  command = plan

  variables {
    bucket_prefix     = "example-"
    sse_algorithm     = "aws:kms:dsse"
    kms_master_key_id = "arn:aws:kms:us-west-2:123456789012:key/external-key-id"
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this.rule).apply_server_side_encryption_by_default[0].sse_algorithm == "aws:kms:dsse"
    error_message = "sse_algorithm aws:kms:dsse should be accepted with kms_master_key_id."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
