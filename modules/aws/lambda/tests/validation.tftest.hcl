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

run "rejects_vpc_config_with_empty_subnet_ids" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
    vpc_config = {
      subnet_ids         = []
      security_group_ids = ["sg-11111111"]
    }
  }

  expect_failures = [var.vpc_config]
}

run "rejects_vpc_config_with_empty_security_group_ids" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
    vpc_config = {
      subnet_ids         = ["subnet-aaaaaaaa"]
      security_group_ids = []
    }
  }

  expect_failures = [var.vpc_config]
}

run "rejects_tracing_config_with_invalid_mode" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
    tracing_config = {
      mode = "Enabled"
    }
  }

  expect_failures = [var.tracing_config]
}

run "rejects_tracing_config_with_wrong_case_mode" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
    tracing_config = {
      mode = "active"
    }
  }

  expect_failures = [var.tracing_config]
}

run "rejects_dead_letter_config_with_non_arn_target" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
    dead_letter_config = {
      target_arn = "my-queue"
    }
  }

  expect_failures = [var.dead_letter_config]
}

run "rejects_dead_letter_config_with_unsupported_service_arn" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
    dead_letter_config = {
      target_arn = "arn:aws:s3:::example-bucket"
    }
  }

  expect_failures = [var.dead_letter_config]
}

run "rejects_negative_reserved_concurrent_executions" {
  command = plan

  variables {
    function_name                  = "example-function"
    filename                       = "function.zip"
    source_code_hash               = "abc123hash=="
    role                           = "arn:aws:iam::123456789012:role/example-lambda-role"
    reserved_concurrent_executions = -2
  }

  expect_failures = [var.reserved_concurrent_executions]
}

run "accepts_unreserved_sentinel_reserved_concurrent_executions" {
  command = plan

  variables {
    function_name                  = "example-function"
    filename                       = "function.zip"
    source_code_hash               = "abc123hash=="
    role                           = "arn:aws:iam::123456789012:role/example-lambda-role"
    reserved_concurrent_executions = -1
  }

  assert {
    condition     = aws_lambda_function.lambda_function.reserved_concurrent_executions == -1
    error_message = "reserved_concurrent_executions should accept AWS's own -1 unreserved sentinel."
  }
}

run "valid_baseline_passes_all_validations" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
    vpc_config = {
      subnet_ids         = ["subnet-aaaaaaaa"]
      security_group_ids = ["sg-11111111"]
    }
    reserved_concurrent_executions = 5
    dead_letter_config = {
      target_arn = "arn:aws:sqs:us-east-1:123456789012:example-dlq"
    }
    tracing_config = {
      mode = "Active"
    }
  }

  assert {
    condition     = aws_lambda_function.lambda_function.reserved_concurrent_executions == 5
    error_message = "valid baseline with every new variable set simultaneously should plan successfully without the validations interfering with one another."
  }
}

# Every expect_failures case above must fail *because* the corresponding validation rejects the
# input. Do NOT weaken these assertions (or any you add) to force a pass -- if a `run` block
# fails to fail (or fails for the wrong reason), fix the validation condition in variables.tf,
# then re-run `tofu test` until it passes for the right reason.
