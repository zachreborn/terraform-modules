mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    name = "example-repo"
  }

  assert {
    condition     = aws_ecr_repository.this.name == "example-repo"
    error_message = "Expected the repository to be planned."
  }
}

run "rejects_invalid_encryption_type" {
  command = plan

  variables {
    name            = "example-repo"
    encryption_type = "INVALID"
  }

  expect_failures = [var.encryption_type]
}

run "rejects_invalid_image_tag_mutability" {
  command = plan

  variables {
    name                 = "example-repo"
    image_tag_mutability = "INVALID"
  }

  expect_failures = [var.image_tag_mutability]
}

run "rejects_invalid_kms_key_arn" {
  command = plan

  variables {
    name    = "example-repo"
    kms_key = "not-a-valid-arn"
  }

  expect_failures = [var.kms_key]
}

run "accepts_valid_kms_key_arn" {
  command = plan

  variables {
    name    = "example-repo"
    kms_key = "arn:aws:kms:us-east-1:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  }

  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].kms_key == "arn:aws:kms:us-east-1:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    error_message = "A valid kms_key ARN should be accepted and passed through."
  }
}

run "accepts_valid_multi_region_kms_key_arn" {
  command = plan

  variables {
    name    = "example-repo"
    kms_key = "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd12ab34cd56ef1234567890ab"
  }

  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].kms_key == "arn:aws:kms:us-east-1:123456789012:key/mrk-1234abcd12ab34cd56ef1234567890ab"
    error_message = "A valid multi-region kms_key ARN should be accepted and passed through."
  }
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
