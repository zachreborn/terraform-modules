mock_provider "aws" {
  mock_resource "aws_lambda_function" {
    defaults = {
      arn = "arn:aws:lambda:us-east-1:123456789012:function:mock-function"
    }
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    function_name    = "example-function"
    description      = "Example Lambda function for testing"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
  }

  assert {
    condition     = aws_lambda_function.lambda_function.function_name == "example-function"
    error_message = "function_name should pass through unchanged."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.description == "Example Lambda function for testing"
    error_message = "description should pass through unchanged."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.handler == "main.handler"
    error_message = "handler should default to main.handler."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.memory_size == 128
    error_message = "memory_size should default to 128."
  }

  # Note: python3.6 is AWS Lambda's actual module default today, but AWS deprecated it for
  # function create/update in 2022 -- a plan with this default succeeds (no client-side
  # runtime validation exists), but a real `apply` against AWS would fail. This assertion
  # documents current behavior; it is not an endorsement of the default. Tracked as
  # https://github.com/zachreborn/terraform-modules/issues/402.
  assert {
    condition     = aws_lambda_function.lambda_function.runtime == "python3.6"
    error_message = "runtime should default to python3.6."
  }

  # Note: variables.tf's description for `timeout` says it "Defaults to 3", but the actual
  # HCL default is 180 -- this assertion documents the real (180) default, which is what a
  # caller actually gets. Tracked as
  # https://github.com/zachreborn/terraform-modules/issues/403.
  assert {
    condition     = aws_lambda_function.lambda_function.timeout == 180
    error_message = "timeout should default to 180."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.environment[0].variables["lambda"] == "true"
    error_message = "variables should default to { lambda = \"true\" }."
  }

  assert {
    condition     = output.arn == "arn:aws:lambda:us-east-1:123456789012:function:mock-function"
    error_message = "arn output should expose the mocked function ARN."
  }
}

run "overrides_are_honored" {
  command = plan

  variables {
    function_name    = "custom-function"
    description      = "Custom description"
    filename         = "custom.zip"
    source_code_hash = "def456hash=="
    role             = "arn:aws:iam::123456789012:role/custom-role"
    handler          = "app.custom_handler"
    memory_size      = 512
    runtime          = "python3.12"
    timeout          = 30
    variables = {
      FOO = "bar"
    }
  }

  assert {
    condition     = aws_lambda_function.lambda_function.handler == "app.custom_handler"
    error_message = "handler override should be honored."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.memory_size == 512
    error_message = "memory_size override should be honored."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.runtime == "python3.12"
    error_message = "runtime override should be honored."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.timeout == 30
    error_message = "timeout override should be honored."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.environment[0].variables["FOO"] == "bar"
    error_message = "variables override should be honored."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
