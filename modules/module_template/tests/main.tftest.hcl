# Blank module test template: uncomment and adapt the block below once this module has at
# least one resource/variable/output to test against. OpenTofu requires every `assert`
# condition to reference a real object from the configuration (a resource, output, or
# variable) — a bare `true`/`false` literal is rejected, so this file intentionally ships
# with no active `run` block until you fill one in.
#
# See AGENTS.md > Module Design Specifications > Native Test Coverage for the full
# requirement, and modules/aws/organizations/tests/ for a worked example.
#
# Every test in this file must run offline via `mock_provider`/`mock_resource` — do not
# require real credentials or a real backend. CI runs these with:
#   tofu init -backend=false && tofu test
#
# mock_provider "aws" {
#   # Add one `mock_resource` block per resource type this module creates, e.g.:
#   #
#   # mock_resource "aws_example_thing" {
#   #   defaults = {
#   #     id  = "example-mock-id"
#   #     arn = "arn:aws:example:us-east-1:123456789012:thing/example-mock-id"
#   #   }
#   # }
# }
#
# run "plan_succeeds_with_valid_input" {
#   command = plan
#
#   variables {
#     # Populate with the minimal set of required variables for a valid plan.
#   }
#
#   assert {
#     condition     = output.example != null
#     error_message = "Replace with a real assertion on this module's outputs/resource counts."
#   }
# }

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
