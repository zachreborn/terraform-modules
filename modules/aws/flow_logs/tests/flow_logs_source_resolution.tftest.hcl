mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-flow-logs-role"
    }
  }
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/mock-flow-logs-policy"
    }
  }
  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:mock-flow-logs-group"
    }
  }
}

run "with_real_target_still_creates_one_flow_log" {
  command = plan

  variables {
    flow_vpc_ids = ["vpc-0123456789abcdef0"]
  }

  assert {
    condition     = length(aws_flow_log.this) == 1
    error_message = "Supplying flow_vpc_ids should still create exactly one flow log."
  }

  assert {
    condition     = aws_flow_log.this[0].vpc_id == "vpc-0123456789abcdef0"
    error_message = "The flow log's vpc_id should equal the supplied target."
  }

  assert {
    condition     = length(output.flow_log_ids) == 1
    error_message = "flow_log_ids should expose exactly one ID when one flow log is created."
  }

  assert {
    condition     = output.flow_log_vpc_ids[0] == "vpc-0123456789abcdef0"
    error_message = "flow_log_vpc_ids should be wired to the created flow log's vpc_id."
  }

  assert {
    condition     = output.flow_log_transit_gateway_ids[0] == null
    error_message = "flow_log_transit_gateway_ids should be null for a flow log targeted at a VPC."
  }

  assert {
    condition     = output.flow_log_transit_gateway_attachment_ids[0] == null
    error_message = "flow_log_transit_gateway_attachment_ids should be null for a flow log targeted at a VPC."
  }
}

run "with_transit_gateway_target_exposes_transit_gateway_output" {
  command = plan

  variables {
    flow_transit_gateway_ids = ["tgw-0123456789abcdef0"]
  }

  assert {
    condition     = length(aws_flow_log.this) == 1
    error_message = "Supplying flow_transit_gateway_ids should create exactly one flow log."
  }

  assert {
    condition     = output.flow_log_transit_gateway_ids[0] == "tgw-0123456789abcdef0"
    error_message = "flow_log_transit_gateway_ids should be wired to the created flow log's transit_gateway_id."
  }

  assert {
    condition     = output.flow_log_vpc_ids[0] == null
    error_message = "flow_log_vpc_ids should be null for a flow log targeted at a transit gateway."
  }

  assert {
    condition     = output.flow_log_transit_gateway_attachment_ids[0] == null
    error_message = "flow_log_transit_gateway_attachment_ids should be null for a flow log targeted at a transit gateway."
  }
}

run "with_transit_gateway_attachment_target_exposes_attachment_output" {
  command = plan

  variables {
    flow_transit_gateway_attachment_ids = ["tgw-attach-0123456789abcdef0"]
  }

  assert {
    condition     = length(aws_flow_log.this) == 1
    error_message = "Supplying flow_transit_gateway_attachment_ids should create exactly one flow log."
  }

  assert {
    condition     = output.flow_log_transit_gateway_attachment_ids[0] == "tgw-attach-0123456789abcdef0"
    error_message = "flow_log_transit_gateway_attachment_ids should be wired to the created flow log's transit_gateway_attachment_id."
  }

  assert {
    condition     = output.flow_log_vpc_ids[0] == null
    error_message = "flow_log_vpc_ids should be null for a flow log targeted at a transit gateway attachment."
  }

  assert {
    condition     = output.flow_log_transit_gateway_ids[0] == null
    error_message = "flow_log_transit_gateway_ids should be null for a flow log targeted at a transit gateway attachment."
  }
}

run "with_no_target_fails_explicit_precondition" {
  command = plan

  expect_failures = [
    aws_kms_key.key,
  ]
}
