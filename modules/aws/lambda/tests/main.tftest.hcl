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

run "tags_default_to_name_only" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
  }

  assert {
    condition     = length(aws_lambda_function.lambda_function.tags) == 1
    error_message = "tags should contain exactly one entry (Name) when tags is omitted."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.tags["Name"] == "example-function"
    error_message = "tags[Name] should default to function_name."
  }
}

run "tags_merge_with_name" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
    tags = {
      Environment = "test"
      Team        = "platform"
    }
  }

  assert {
    condition     = aws_lambda_function.lambda_function.tags["Name"] == "example-function"
    error_message = "tags[Name] should default to function_name even when other tags are supplied."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.tags["Environment"] == "test"
    error_message = "caller-supplied Environment tag should land unchanged."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.tags["Team"] == "platform"
    error_message = "caller-supplied Team tag should land unchanged."
  }
}

run "caller_supplied_name_tag_wins" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
    tags = {
      Name = "custom-name"
    }
  }

  assert {
    condition     = aws_lambda_function.lambda_function.tags["Name"] == "custom-name"
    error_message = "a caller-supplied Name tag should win over the automatic function_name-derived Name."
  }
}

run "outputs_expose_function_attributes" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
  }

  assert {
    condition     = output.arn == "arn:aws:lambda:us-east-1:123456789012:function:mock-function"
    error_message = "arn output should expose the mocked function ARN."
  }

  assert {
    condition     = output.function_name == "example-function"
    error_message = "function_name output should equal the function_name input."
  }

  assert {
    condition     = output.invoke_arn == "arn:aws:apigateway:us-east-1:lambda:path/2015-03-31/functions/arn:aws:lambda:us-east-1:123456789012:function:mock-function/invocations"
    error_message = "invoke_arn output should expose the mocked invoke ARN."
  }

  assert {
    condition     = output.qualified_arn == "arn:aws:lambda:us-east-1:123456789012:function:mock-function:1"
    error_message = "qualified_arn output should expose the mocked qualified ARN."
  }

  assert {
    condition     = output.version == "1"
    error_message = "version output should expose the mocked version."
  }

  assert {
    condition     = output.last_modified == "2024-01-01T00:00:00.000+0000"
    error_message = "last_modified output should expose the mocked last_modified value."
  }

  assert {
    condition     = length(output.tags_all) == 0
    error_message = "tags_all output should expose the mocked tags_all value."
  }
}

# aws_lambda_function's schema declares ExactlyOneOf(filename, image_uri, s3_bucket), so a plan
# that omits all three can never succeed -- this module has no s3_bucket/image_uri input (out of
# scope per the approved spec's § 2/§ 9), so `filename` must stay supplied here. This case targets
# the actual regression the spec's acceptance criteria call out: omitting `description` (now
# `default = null`) no longer fails with "No value for required variable".
#
# `source_code_hash` is intentionally not asserted here: it is `Optional: true, Computed: true`
# in the aws_lambda_function schema (confirmed against hashicorp/aws v6.66.0's
# internal/service/lambda/function.go), so when it is omitted from config, both the real provider
# and mock_provider compute a value for it rather than leaving it null -- asserting `== null`
# would be testing mock-fixture behavior, not real module behavior. The regression this module
# actually fixes (no "No value for required variable" error) is already proven by this run block
# planning successfully with `source_code_hash` omitted.
run "omitting_description_plans_successfully" {
  command = plan

  variables {
    function_name = "example-function"
    filename      = "function.zip"
    role          = "arn:aws:iam::123456789012:role/example-lambda-role"
  }

  assert {
    condition     = aws_lambda_function.lambda_function.description == null
    error_message = "description should be null when omitted."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
