mock_provider "aws" {
  mock_resource "aws_dx_gateway" {
    defaults = {
      id               = "abcd1234-dcba-5678-be23-cdef9876ab45"
      arn              = "arn:aws:directconnect::123456789012:dx-gateway/abcd1234-dcba-5678-be23-cdef9876ab45"
      owner_account_id = "123456789012"
    }
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    name            = "example-gateway"
    amazon_side_asn = "64512"
  }

  assert {
    condition     = aws_dx_gateway.this.tags["Name"] == "example-gateway"
    error_message = "A Name tag should default to var.name."
  }

  assert {
    condition     = output.arn == "arn:aws:directconnect::123456789012:dx-gateway/abcd1234-dcba-5678-be23-cdef9876ab45"
    error_message = "arn output should expose the mocked gateway ARN."
  }

  assert {
    condition     = output.id == "abcd1234-dcba-5678-be23-cdef9876ab45"
    error_message = "id output should expose the mocked gateway id."
  }

  assert {
    condition     = output.owner_account_id == "123456789012"
    error_message = "owner_account_id output should expose the mocked value."
  }
}

run "tags_merge_module_and_provided_tags" {
  command = plan

  variables {
    name            = "example-gateway"
    amazon_side_asn = "64512"
    tags = {
      team = "networking"
    }
  }

  assert {
    condition     = aws_dx_gateway.this.tags["team"] == "networking"
    error_message = "Caller-provided tags should be merged in."
  }

  assert {
    condition     = aws_dx_gateway.this.tags["Name"] == "example-gateway"
    error_message = "Name tag should still be present alongside merged tags."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
