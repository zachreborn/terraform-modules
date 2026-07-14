mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }
}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    ami                    = "ami-0123456789abcdef0"
    instance_type          = "t3.micro"
    name                   = "example"
    vpc_security_group_ids = ["sg-0123456789abcdef0"]
  }

  assert {
    condition     = length(aws_instance.ec2) == 1
    error_message = "Expected exactly one instance to be planned."
  }
}

# Note: ami's validation regex (`^ami-`) only checks the prefix, so it also accepts
# malformed values such as "ami-" or "ami-not-hex" that are not real AMI IDs -- tracked as
# https://github.com/zachreborn/terraform-modules/issues/404. "invalid-ami-id" is used here
# because it lacks the ami- prefix entirely, so it correctly fails both today and after that
# bug is fixed.
run "rejects_invalid_ami" {
  command = plan

  variables {
    ami                    = "invalid-ami-id"
    instance_type          = "t3.micro"
    name                   = "example"
    vpc_security_group_ids = ["sg-0123456789abcdef0"]
  }

  expect_failures = [var.ami]
}

# instance_initiated_shutdown_behavior's validation regex is anchored (`^(stop|terminate)$`),
# so a value that is neither accepted token fails.
run "rejects_invalid_instance_initiated_shutdown_behavior" {
  command = plan

  variables {
    ami                                  = "ami-0123456789abcdef0"
    instance_type                        = "t3.micro"
    name                                 = "example"
    vpc_security_group_ids               = ["sg-0123456789abcdef0"]
    instance_initiated_shutdown_behavior = "reboot"
  }

  expect_failures = [var.instance_initiated_shutdown_behavior]
}

# Regression case for https://github.com/zachreborn/terraform-modules/issues/396: before the
# regex was anchored, "stop-now" passed because the unanchored `stop|terminate` matched the
# "stop" substring. With the anchored `^(stop|terminate)$` it now correctly fails.
run "rejects_shutdown_behavior_substring_match" {
  command = plan

  variables {
    ami                                  = "ami-0123456789abcdef0"
    instance_type                        = "t3.micro"
    name                                 = "example"
    vpc_security_group_ids               = ["sg-0123456789abcdef0"]
    instance_initiated_shutdown_behavior = "stop-now"
  }

  expect_failures = [var.instance_initiated_shutdown_behavior]
}

# Covers the non-default valid enum member for instance_initiated_shutdown_behavior.
run "accepts_valid_shutdown_behavior_terminate" {
  command = plan

  variables {
    ami                                  = "ami-0123456789abcdef0"
    instance_type                        = "t3.micro"
    name                                 = "example"
    vpc_security_group_ids               = ["sg-0123456789abcdef0"]
    instance_initiated_shutdown_behavior = "terminate"
  }

  assert {
    condition     = aws_instance.ec2[0].instance_initiated_shutdown_behavior == "terminate"
    error_message = "Expected instance_initiated_shutdown_behavior to be terminate."
  }
}

run "rejects_invalid_http_endpoint" {
  command = plan

  variables {
    ami                    = "ami-0123456789abcdef0"
    instance_type          = "t3.micro"
    name                   = "example"
    vpc_security_group_ids = ["sg-0123456789abcdef0"]
    http_endpoint          = "invalid"
  }

  expect_failures = [var.http_endpoint]
}

run "rejects_invalid_http_tokens" {
  command = plan

  variables {
    ami                    = "ami-0123456789abcdef0"
    instance_type          = "t3.micro"
    name                   = "example"
    vpc_security_group_ids = ["sg-0123456789abcdef0"]
    http_tokens            = "invalid"
  }

  expect_failures = [var.http_tokens]
}

run "rejects_invalid_root_volume_type" {
  command = plan

  variables {
    ami                    = "ami-0123456789abcdef0"
    instance_type          = "t3.micro"
    name                   = "example"
    vpc_security_group_ids = ["sg-0123456789abcdef0"]
    root_volume_type       = "invalid"
  }

  expect_failures = [var.root_volume_type]
}

run "rejects_invalid_tenancy" {
  command = plan

  variables {
    ami                    = "ami-0123456789abcdef0"
    instance_type          = "t3.micro"
    name                   = "example"
    vpc_security_group_ids = ["sg-0123456789abcdef0"]
    tenancy                = "invalid"
  }

  expect_failures = [var.tenancy]
}

# auto_recovery's validation regex is anchored (`^(default|disabled)$`), so a value that is
# neither accepted token fails.
#
# Separately, var.auto_recovery is never referenced by aws_instance.ec2 in main.tf, so even
# though this variable is validated, setting it to a valid value (e.g. "disabled") has no
# effect on the plan -- tracked as
# https://github.com/zachreborn/terraform-modules/issues/397. No default/override assertion
# for auto_recovery is added to tests/main.tftest.hcl until that wiring exists, since there is
# nothing in the plan for such an assertion to observe.
run "rejects_invalid_auto_recovery" {
  command = plan

  variables {
    ami                    = "ami-0123456789abcdef0"
    instance_type          = "t3.micro"
    name                   = "example"
    vpc_security_group_ids = ["sg-0123456789abcdef0"]
    auto_recovery          = "invalid"
  }

  expect_failures = [var.auto_recovery]
}

# Regression case for https://github.com/zachreborn/terraform-modules/issues/396: before the
# regex was anchored, "default-invalid" passed because the unanchored `default|disabled`
# matched the "default" substring. With the anchored `^(default|disabled)$` it now correctly
# fails.
run "rejects_auto_recovery_substring_match" {
  command = plan

  variables {
    ami                    = "ami-0123456789abcdef0"
    instance_type          = "t3.micro"
    name                   = "example"
    vpc_security_group_ids = ["sg-0123456789abcdef0"]
    auto_recovery          = "default-invalid"
  }

  expect_failures = [var.auto_recovery]
}

# Covers the non-default valid enum member for auto_recovery. Because auto_recovery is not
# wired into aws_instance.ec2 (see issue #397), this only asserts that a valid value still
# lets the plan succeed rather than asserting on a resource attribute.
run "accepts_valid_auto_recovery_disabled" {
  command = plan

  variables {
    ami                    = "ami-0123456789abcdef0"
    instance_type          = "t3.micro"
    name                   = "example"
    vpc_security_group_ids = ["sg-0123456789abcdef0"]
    auto_recovery          = "disabled"
  }

  assert {
    condition     = length(aws_instance.ec2) == 1
    error_message = "Expected exactly one instance to be planned with auto_recovery = disabled."
  }
}

# Note on bool-typed variables (associate_public_ip_address, disable_api_termination,
# ebs_optimized, encrypted, root_delete_on_termination, source_dest_check): each declares a
# `validation { condition = can(regex("^(true|false)$", var.x)) }` block, but since the
# variable's declared type is already `bool`, OpenTofu coerces the value to a real boolean
# (or rejects it with a type error) before the validation block ever runs. There is no value
# that is simultaneously a valid `bool` and a regex mismatch, so these validation blocks can
# never actually fail and have no distinct expect_failures case to test. Confirmed empirically:
# passing a non-boolean string (e.g. "notabool") produces a type-conversion error attributed to
# the variable's type constraint, not the validation block, and tofu test's expect_failures
# reports "Missing expected failure" for it. This is a pre-existing quirk of the module's
# variables.tf (dead validation code), not something this test suite works around by skipping
# coverage that is otherwise achievable.

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
