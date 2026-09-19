mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    domain_id         = "d-0123456789ab"
    user_profile_name = "data-scientist-jane"
    user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
  }

  assert {
    condition     = aws_sagemaker_user_profile.this.user_profile_name == "data-scientist-jane"
    error_message = "Expected the user profile to be planned with the given user_profile_name."
  }
}

run "rejects_invalid_single_sign_on_user_identifier" {
  command = plan

  variables {
    domain_id                      = "d-0123456789ab"
    user_profile_name              = "jane-doe"
    single_sign_on_user_identifier = "Email"
    single_sign_on_user_value      = "jane.doe"
    user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
  }

  expect_failures = [var.single_sign_on_user_identifier]
}

run "accepts_valid_single_sign_on_user_identifier" {
  command = plan

  variables {
    domain_id                      = "d-0123456789ab"
    user_profile_name              = "jane-doe"
    single_sign_on_user_identifier = "UserName"
    single_sign_on_user_value      = "jane.doe"
    user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
  }

  assert {
    condition     = aws_sagemaker_user_profile.this.single_sign_on_user_identifier == "UserName"
    error_message = "Expected single_sign_on_user_identifier to be UserName."
  }
}

# Regression guard for the single_sign_on_user_identifier / single_sign_on_user_value
# lifecycle.precondition added to aws_sagemaker_user_profile.this: the two fields must either
# both be set (SSO domains) or both be null (IAM domains). Setting only one must fail the plan
# even though single_sign_on_user_identifier's own validation block passes.
run "rejects_identifier_set_without_value" {
  command = plan

  variables {
    domain_id                      = "d-0123456789ab"
    user_profile_name              = "jane-doe"
    single_sign_on_user_identifier = "UserName"
    user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
  }

  expect_failures = [aws_sagemaker_user_profile.this]
}

run "rejects_value_set_without_identifier" {
  command = plan

  variables {
    domain_id                 = "d-0123456789ab"
    user_profile_name         = "jane-doe"
    single_sign_on_user_value = "jane.doe"
    user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
  }

  expect_failures = [aws_sagemaker_user_profile.this]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}`/`precondition {}` block has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
