mock_provider "aws" {}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    name = "example-app"
  }

  assert {
    condition     = output.id != null
    error_message = "Expected the namespace id output to resolve."
  }

  assert {
    condition     = output.arn != null
    error_message = "Expected the namespace arn output to resolve."
  }

  assert {
    condition     = output.name == "example-app"
    error_message = "Expected the namespace name output to echo the input name."
  }
}
