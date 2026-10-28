mock_provider "aws" {
  mock_resource "aws_sqs_queue" {
    defaults = { tags_all = { Name = "caller", Team = "platform" } }
  }
}

variables {
  name                    = "work"
  create_kms_key          = false
  sqs_managed_sse_enabled = true
}

# Separate state avoids cached computed tags from earlier mocked applies.
run "caller_name_output" {
  command = apply
  variables {
    tags = { Name = "caller", Team = "platform" }
  }
  assert {
    condition     = aws_sqs_queue.queue.tags == tomap({ Name = "caller", Team = "platform" }) && output.tags_all == tomap({ Name = "caller", Team = "platform" })
    error_message = "Caller Name overrides must reach configured tags and the provider-shaped output exactly."
  }
}
