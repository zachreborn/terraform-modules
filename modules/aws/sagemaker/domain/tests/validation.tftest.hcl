mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    domain_name = "ml-platform"
    auth_mode   = "IAM"
    vpc_id      = "vpc-0123456789abcdef0"
    subnet_ids  = ["subnet-0123456789abcdef0"]
    default_user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
  }

  assert {
    condition     = aws_sagemaker_domain.this.domain_name == "ml-platform"
    error_message = "Expected the domain to be planned with the given domain_name."
  }
}

run "rejects_invalid_auth_mode" {
  command = plan

  variables {
    domain_name = "ml-platform"
    auth_mode   = "OAUTH"
    vpc_id      = "vpc-0123456789abcdef0"
    subnet_ids  = ["subnet-0123456789abcdef0"]
    default_user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
  }

  expect_failures = [var.auth_mode]
}

run "accepts_valid_auth_mode_sso" {
  command = plan

  variables {
    domain_name = "ml-platform"
    auth_mode   = "SSO"
    vpc_id      = "vpc-0123456789abcdef0"
    subnet_ids  = ["subnet-0123456789abcdef0"]
    default_user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
  }

  assert {
    condition     = aws_sagemaker_domain.this.auth_mode == "SSO"
    error_message = "Expected auth_mode to be SSO."
  }
}

run "rejects_invalid_app_network_access_type" {
  command = plan

  variables {
    domain_name             = "ml-platform"
    auth_mode               = "IAM"
    vpc_id                  = "vpc-0123456789abcdef0"
    subnet_ids              = ["subnet-0123456789abcdef0"]
    app_network_access_type = "invalid"
    default_user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
  }

  expect_failures = [var.app_network_access_type]
}

run "rejects_invalid_app_security_group_management" {
  command = plan

  variables {
    domain_name                   = "ml-platform"
    auth_mode                     = "IAM"
    vpc_id                        = "vpc-0123456789abcdef0"
    subnet_ids                    = ["subnet-0123456789abcdef0"]
    app_security_group_management = "invalid"
    default_user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
  }

  expect_failures = [var.app_security_group_management]
}

run "rejects_invalid_tag_propagation" {
  command = plan

  variables {
    domain_name     = "ml-platform"
    auth_mode       = "IAM"
    vpc_id          = "vpc-0123456789abcdef0"
    subnet_ids      = ["subnet-0123456789abcdef0"]
    tag_propagation = "invalid"
    default_user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
  }

  expect_failures = [var.tag_propagation]
}

# Regression guard for the app_security_group_management / app_network_access_type
# lifecycle.precondition added to aws_sagemaker_domain.this: app_security_group_management
# is only meaningful under VpcOnly, so setting it alongside PublicInternetOnly must fail the
# plan even though both individual variable values pass their own validation blocks.
run "rejects_app_security_group_management_with_public_internet_only" {
  command = plan

  variables {
    domain_name                   = "ml-platform"
    auth_mode                     = "IAM"
    vpc_id                        = "vpc-0123456789abcdef0"
    subnet_ids                    = ["subnet-0123456789abcdef0"]
    app_network_access_type       = "PublicInternetOnly"
    app_security_group_management = "Service"
    default_user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
  }

  expect_failures = [aws_sagemaker_domain.this]
}

run "accepts_app_security_group_management_with_vpc_only" {
  command = plan

  variables {
    domain_name                   = "ml-platform"
    auth_mode                     = "IAM"
    vpc_id                        = "vpc-0123456789abcdef0"
    subnet_ids                    = ["subnet-0123456789abcdef0"]
    app_network_access_type       = "VpcOnly"
    app_security_group_management = "Service"
    default_user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
  }

  assert {
    condition     = aws_sagemaker_domain.this.app_security_group_management == "Service"
    error_message = "app_security_group_management should be accepted alongside VpcOnly."
  }
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}`/`precondition {}` block has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
