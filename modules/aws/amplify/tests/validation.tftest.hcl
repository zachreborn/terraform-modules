mock_provider "aws" {
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

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    name              = "my-app"
    branches          = {}
    cache_config_type = "AMPLIFY_MANAGED"
    platform          = "WEB"
  }

  assert {
    condition     = aws_amplify_app.this.name == "my-app"
    error_message = "Expected the app to plan successfully with valid inputs."
  }
}

run "rejects_invalid_cache_config_type" {
  command = plan

  variables {
    name              = "my-app"
    branches          = {}
    cache_config_type = "NOT_A_REAL_CACHE_TYPE"
  }

  expect_failures = [var.cache_config_type]
}

run "rejects_invalid_platform" {
  command = plan

  variables {
    name     = "my-app"
    branches = {}
    platform = "NOT_A_REAL_PLATFORM"
  }

  expect_failures = [var.platform]
}

run "notifications_without_sns_topic_arn_or_create_sns_topic_fails_precondition" {
  command = plan

  variables {
    name                 = "my-app"
    branches             = {}
    enable_notifications = true
    create_sns_topic     = false
  }

  expect_failures = [aws_amplify_app.this]
}

run "notification_emails_with_external_topic_fails_precondition" {
  command = plan

  variables {
    name                 = "my-app"
    branches             = {}
    enable_notifications = true
    create_sns_topic     = false
    sns_topic_arn        = "arn:aws:sns:us-east-1:123456789012:external-topic"
    notification_emails  = ["ops@example.com"]
  }

  expect_failures = [aws_amplify_app.this]
}

run "notifications_with_external_topic_and_no_emails_plans_successfully" {
  command = plan

  variables {
    name                 = "my-app"
    branches             = {}
    enable_notifications = true
    create_sns_topic     = false
    sns_topic_arn        = "arn:aws:sns:us-east-1:123456789012:external-topic"
  }

  assert {
    condition     = output.sns_topic_arn == "arn:aws:sns:us-east-1:123456789012:external-topic"
    error_message = "Expected the precondition to pass and sns_topic_arn to echo the caller-supplied topic."
  }
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}`/`precondition {}` block has a bug or the test's inputs are wrong -- find
# and fix the root cause, then re-run `tofu test` until it passes for the right reason.

run "rejects_sub_domains_without_domain_name" {
  command = plan

  variables {
    name = "my-app"
    branches = {
      main = {
        sub_domains = ["www"]
      }
    }
  }

  expect_failures = [var.branches]
}

run "rejects_custom_certificate_arn_without_domain_name" {
  command = plan

  variables {
    name = "my-app"
    branches = {
      main = {
        custom_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
      }
    }
  }

  expect_failures = [var.branches]
}

# enable_domain_association = true cannot create an association without a domain_name.
run "rejects_enable_domain_association_true_without_domain_name" {
  command = plan

  variables {
    name = "my-app"
    branches = {
      main = {
        enable_domain_association = true
      }
    }
  }

  expect_failures = [var.branches]
}

# enable_domain_association = false skips the association, so domain-only settings that have no
# non-null default would be silently ignored; reject them just like the no-domain_name case.
run "rejects_sub_domains_when_enable_domain_association_false" {
  command = plan

  variables {
    name = "my-app"
    branches = {
      main = {
        domain_name               = "example.org"
        enable_domain_association = false
        sub_domains               = ["www"]
      }
    }
  }

  expect_failures = [var.branches]
}

run "rejects_custom_certificate_arn_when_enable_domain_association_false" {
  command = plan

  variables {
    name = "my-app"
    branches = {
      main = {
        custom_certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
        domain_name               = "example.org"
        enable_domain_association = false
      }
    }
  }

  expect_failures = [var.branches]
}

run "enable_domain_association_false_with_domain_name_passes_validation" {
  command = plan

  variables {
    name = "my-app"
    branches = {
      main = {
        domain_name               = "example.org"
        enable_domain_association = false
        framework                 = "Astro"
      }
    }
  }

  assert {
    condition     = length(aws_amplify_branch.this) == 1
    error_message = "A branch that opts out of the domain association without domain-only settings should be accepted."
  }

  assert {
    condition     = length(aws_amplify_domain_association.this) == 0
    error_message = "No domain association should be planned when enable_domain_association = false."
  }
}

run "branch_without_domain_name_passes_validation" {
  command = plan

  variables {
    name = "my-app"
    branches = {
      main = {
        framework = "Astro"
        stage     = "EXPERIMENTAL"
      }
    }
  }

  assert {
    condition     = length(aws_amplify_branch.this) == 1
    error_message = "A branch without domain_name and without domain-only settings should be accepted."
  }
}
