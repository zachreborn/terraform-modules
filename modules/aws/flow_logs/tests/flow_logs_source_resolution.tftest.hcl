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
}

run "with_no_target_creates_zero_flow_logs" {
  command = plan

  assert {
    condition     = length(aws_flow_log.this) == 0
    error_message = "Supplying no target at all should create zero flow logs (not crash)."
  }
}
