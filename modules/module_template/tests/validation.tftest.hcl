# Blank module validation-test template: for every `validation { ... }` block you add to a
# variable in variables.tf, add one "valid baseline" run block (proves the happy path still
# plans) and one `expect_failures` run block per distinct way the validation can fail below.
#
# See modules/aws/organizations/account/tests/validation.tftest.hcl for a worked example of
# this pattern (rejects_entry_with_both_x_and_y, rejects_entry_with_neither_x_nor_y, etc.).
#
# mock_provider "aws" {}
#
# run "valid_baseline_does_not_fail" {
#   command = plan
#
#   variables {
#     # Minimal input that satisfies every validation block.
#   }
#
#   assert {
#     condition     = true
#     error_message = "Replace with a real assertion once this module has variables."
#   }
# }
#
# run "rejects_invalid_example" {
#   command = plan
#
#   variables {
#     # Input that violates one specific validation rule.
#   }
#
#   expect_failures = [var.example]
# }

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong — find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
