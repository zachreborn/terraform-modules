mock_provider "aws" {
  mock_resource "aws_lambda_function" {
    defaults = {
      arn           = "arn:aws:lambda:us-east-1:123456789012:function:mock-function"
      invoke_arn    = "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:mock-function/invocations"
      qualified_arn = "arn:aws:lambda:us-east-1:123456789012:function:mock-function:1"
      version       = "1"
      last_modified = "2024-01-01T00:00:00.000+0000"
      tags_all      = {}
    }
  }
}

run "vpc_config_omitted_creates_no_vpc_block" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
  }

  assert {
    condition     = length(aws_lambda_function.lambda_function.vpc_config) == 0
    error_message = "vpc_config should produce no block when omitted."
  }
}

run "vpc_config_attaches_subnets_and_security_groups" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
    vpc_config = {
      subnet_ids         = ["subnet-aaaaaaaa", "subnet-bbbbbbbb"]
      security_group_ids = ["sg-11111111"]
    }
  }

  assert {
    condition     = aws_lambda_function.lambda_function.vpc_config[0].subnet_ids == toset(["subnet-aaaaaaaa", "subnet-bbbbbbbb"])
    error_message = "vpc_config subnet_ids should contain exactly the supplied subnet IDs."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.vpc_config[0].security_group_ids == toset(["sg-11111111"])
    error_message = "vpc_config security_group_ids should contain exactly the supplied security group IDs."
  }
}

run "vpc_config_ipv6_allowed_for_dual_stack_enabled" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
    vpc_config = {
      subnet_ids                  = ["subnet-aaaaaaaa", "subnet-bbbbbbbb"]
      security_group_ids          = ["sg-11111111"]
      ipv6_allowed_for_dual_stack = true
    }
  }

  assert {
    condition     = aws_lambda_function.lambda_function.vpc_config[0].ipv6_allowed_for_dual_stack == true
    error_message = "ipv6_allowed_for_dual_stack should be wired through to the vpc_config block rather than dropped."
  }
}

run "dead_letter_config_omitted_creates_no_block" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
  }

  assert {
    condition     = length(aws_lambda_function.lambda_function.dead_letter_config) == 0
    error_message = "dead_letter_config should produce no block when omitted."
  }
}

run "dead_letter_config_sets_target_arn" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
    dead_letter_config = {
      target_arn = "arn:aws:sqs:us-east-1:123456789012:example-dlq"
    }
  }

  assert {
    condition     = aws_lambda_function.lambda_function.dead_letter_config[0].target_arn == "arn:aws:sqs:us-east-1:123456789012:example-dlq"
    error_message = "dead_letter_config target_arn should match the supplied SQS ARN."
  }
}

run "tracing_config_omitted_creates_no_block" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
  }

  assert {
    condition     = length(aws_lambda_function.lambda_function.tracing_config) == 0
    error_message = "tracing_config should produce no block when omitted."
  }
}

run "tracing_config_active" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
    tracing_config = {
      mode = "Active"
    }
  }

  assert {
    condition     = aws_lambda_function.lambda_function.tracing_config[0].mode == "Active"
    error_message = "tracing_config mode should accept Active."
  }
}

run "tracing_config_passthrough" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
    tracing_config = {
      mode = "PassThrough"
    }
  }

  assert {
    condition     = aws_lambda_function.lambda_function.tracing_config[0].mode == "PassThrough"
    error_message = "tracing_config mode should accept PassThrough."
  }
}

run "reserved_concurrent_executions_omitted_is_unreserved" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
  }

  assert {
    condition     = aws_lambda_function.lambda_function.reserved_concurrent_executions == null
    error_message = "reserved_concurrent_executions should plan as null (unreserved) when omitted."
  }
}

run "reserved_concurrent_executions_set" {
  command = plan

  variables {
    function_name                  = "example-function"
    filename                       = "function.zip"
    source_code_hash               = "abc123hash=="
    role                           = "arn:aws:iam::123456789012:role/example-lambda-role"
    reserved_concurrent_executions = 5
  }

  assert {
    condition     = aws_lambda_function.lambda_function.reserved_concurrent_executions == 5
    error_message = "reserved_concurrent_executions should pass through the supplied value."
  }
}

run "reserved_concurrent_executions_zero_throttles_function" {
  command = plan

  variables {
    function_name                  = "example-function"
    filename                       = "function.zip"
    source_code_hash               = "abc123hash=="
    role                           = "arn:aws:iam::123456789012:role/example-lambda-role"
    reserved_concurrent_executions = 0
  }

  assert {
    condition     = aws_lambda_function.lambda_function.reserved_concurrent_executions == 0
    error_message = "reserved_concurrent_executions of 0 should be passed through rather than treated as unset by a falsy check."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
