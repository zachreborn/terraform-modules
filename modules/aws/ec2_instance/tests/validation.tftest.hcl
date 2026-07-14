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

# Note: instance_initiated_shutdown_behavior's validation regex (`stop|terminate`) is
# unanchored, so it also accepts invalid substring matches such as "stop-now" -- tracked as
# https://github.com/zachreborn/terraform-modules/issues/396. "reboot" is used here (rather
# than a substring-match case like "stop-now") because it is a value that correctly fails
# both today and after that bug is fixed, keeping this test meaningful in the meantime.
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

# Note: auto_recovery's validation regex (`default|disabled`) is unanchored, so it also
# accepts invalid substring matches such as "default-invalid" -- tracked as
# https://github.com/zachreborn/terraform-modules/issues/396. "invalid" is used here because
# it contains neither accepted token, so it correctly fails both today and after that bug is
# fixed.
#
# var.auto_recovery is now wired into aws_instance.ec2 via a maintenance_options {} block in
# main.tf (fixed in https://github.com/zachreborn/terraform-modules/issues/397), so its
# default and override behavior is asserted in tests/main.tftest.hcl
# (maintenance_options[0].auto_recovery == "default" / "disabled"). This case covers only the
# variable's validation {} rule.
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
