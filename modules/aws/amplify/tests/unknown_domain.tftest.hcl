# Native OpenTofu test for modules/aws/amplify -- a branch domain_name that is known only after apply.
#
# The harness in ./tests/unknown_domain feeds a terraform_data output (unknown at plan time) into one
# branch's domain_name. aws_amplify_domain_association.this uses for_each, and for_each keys must be
# known at plan time, so which branches get an association must not depend on the *value* of an
# apply-time domain_name. The branch opts in with enable_domain_association = true (a plan-known
# flag) instead of relying on a null check of the unknown value, which would fail with "Invalid
# for_each argument". The plan must succeed and still plan both branches.
#
# Run offline with:
#   tofu -chdir=modules/aws/amplify init -backend=false
#   tofu -chdir=modules/aws/amplify test

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

  mock_resource "aws_amplify_app" {
    defaults = {
      id             = "d1234567890abc"
      arn            = "arn:aws:amplify:us-east-1:123456789012:apps/d1234567890abc"
      default_domain = "d1234567890abc.amplifyapp.com"
    }
  }
}

run "computed_domain_name_plans_successfully" {
  command = plan
  module {
    source = "./tests/unknown_domain"
  }

  assert {
    condition     = contains(keys(output.branch_urls), "main")
    error_message = "The branch with an apply-time domain_name should still be planned."
  }

  assert {
    condition     = contains(keys(output.branch_urls), "poc")
    error_message = "The domain-less branch should still be planned."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a signal that the
# module code has a bug and fix the root cause in main.tf / variables.tf / outputs.tf, then re-run
# `tofu test` until it passes for the right reason.
