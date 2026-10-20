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

# Container-image (package_type = "Image") support. Zip behavior is covered by main.tftest.hcl and
# must not change: with package_type left null, handler/runtime still pass through as before.

run "image_function_plans_successfully" {
  command = plan

  variables {
    function_name = "example-image-function"
    role          = "arn:aws:iam::123456789012:role/example-lambda-role"
    package_type  = "Image"
    image_uri     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/example:v1.0.0"
  }

  assert {
    condition     = aws_lambda_function.lambda_function.package_type == "Image"
    error_message = "package_type should be passed through as Image."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.image_uri == "123456789012.dkr.ecr.us-east-1.amazonaws.com/example:v1.0.0"
    error_message = "image_uri should pass through unchanged."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.filename == null
    error_message = "filename should stay null for an image function."
  }
}

run "image_function_ignores_handler_and_runtime_defaults" {
  command = plan

  variables {
    function_name = "example-image-function"
    role          = "arn:aws:iam::123456789012:role/example-lambda-role"
    package_type  = "Image"
    image_uri     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/example:v1.0.0"
  }

  # The provider rejects handler/runtime for Image functions, so the module must null them out even
  # though their zip-oriented defaults ("main.handler", "python3.6") are non-null.
  assert {
    condition     = aws_lambda_function.lambda_function.handler == null
    error_message = "handler must be null for an image function, even though it has a non-null default."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.runtime == null
    error_message = "runtime must be null for an image function, even though it has a non-null default."
  }
}

run "image_function_ignores_explicit_handler_and_runtime" {
  command = plan

  variables {
    function_name = "example-image-function"
    role          = "arn:aws:iam::123456789012:role/example-lambda-role"
    package_type  = "Image"
    image_uri     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/example:v1.0.0"
    handler       = "app.handler"
    runtime       = "python3.12"
  }

  assert {
    condition     = aws_lambda_function.lambda_function.handler == null
    error_message = "an explicit handler must still be dropped for an image function."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.runtime == null
    error_message = "an explicit runtime must still be dropped for an image function."
  }
}

run "explicit_zip_package_type_keeps_handler_and_runtime" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
    package_type     = "Zip"
    handler          = "app.custom_handler"
    runtime          = "python3.12"
  }

  assert {
    condition     = aws_lambda_function.lambda_function.package_type == "Zip"
    error_message = "package_type should accept an explicit Zip."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.handler == "app.custom_handler"
    error_message = "handler must still pass through for a zip function."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.runtime == "python3.12"
    error_message = "runtime must still pass through for a zip function."
  }
}

run "zip_function_with_omitted_new_inputs_is_unchanged" {
  command = plan

  variables {
    function_name    = "example-function"
    filename         = "function.zip"
    source_code_hash = "abc123hash=="
    role             = "arn:aws:iam::123456789012:role/example-lambda-role"
  }

  assert {
    condition     = aws_lambda_function.lambda_function.handler == "main.handler"
    error_message = "handler default must be unchanged for existing zip callers."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.runtime == "python3.6"
    error_message = "runtime default must be unchanged for existing zip callers."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.image_uri == null
    error_message = "image_uri should be null when omitted."
  }

  assert {
    condition     = length(aws_lambda_function.lambda_function.ephemeral_storage) == 0 || aws_lambda_function.lambda_function.ephemeral_storage[0].size == 512
    error_message = "ephemeral_storage should not be customized when ephemeral_storage_size is omitted."
  }

  assert {
    condition     = length(aws_lambda_function.lambda_function.image_config) == 0
    error_message = "image_config should produce no block when omitted."
  }
}

run "architectures_arm64_is_wired_through" {
  command = plan

  variables {
    function_name = "example-image-function"
    role          = "arn:aws:iam::123456789012:role/example-lambda-role"
    package_type  = "Image"
    image_uri     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/example:v1.0.0"
    architectures = ["arm64"]
  }

  assert {
    condition     = aws_lambda_function.lambda_function.architectures == tolist(["arm64"])
    error_message = "architectures should be wired through to the function."
  }
}

run "ephemeral_storage_size_is_wired_through" {
  command = plan

  variables {
    function_name          = "example-image-function"
    role                   = "arn:aws:iam::123456789012:role/example-lambda-role"
    package_type           = "Image"
    image_uri              = "123456789012.dkr.ecr.us-east-1.amazonaws.com/example:v1.0.0"
    ephemeral_storage_size = 2048
  }

  assert {
    condition     = aws_lambda_function.lambda_function.ephemeral_storage[0].size == 2048
    error_message = "ephemeral_storage_size should be wired through to the ephemeral_storage block."
  }
}

run "image_config_is_wired_through" {
  command = plan

  variables {
    function_name = "example-image-function"
    role          = "arn:aws:iam::123456789012:role/example-lambda-role"
    package_type  = "Image"
    image_uri     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/example:v1.0.0"
    image_config = {
      command           = ["app.handler"]
      entry_point       = ["/lambda-entrypoint.sh"]
      working_directory = "/var/task"
    }
  }

  assert {
    condition     = aws_lambda_function.lambda_function.image_config[0].command == tolist(["app.handler"])
    error_message = "image_config.command should be wired through."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.image_config[0].entry_point == tolist(["/lambda-entrypoint.sh"])
    error_message = "image_config.entry_point should be wired through."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.image_config[0].working_directory == "/var/task"
    error_message = "image_config.working_directory should be wired through."
  }
}

run "image_config_partial_object_leaves_other_fields_null" {
  command = plan

  variables {
    function_name = "example-image-function"
    role          = "arn:aws:iam::123456789012:role/example-lambda-role"
    package_type  = "Image"
    image_uri     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/example:v1.0.0"
    image_config = {
      command = ["app.handler"]
    }
  }

  assert {
    condition     = aws_lambda_function.lambda_function.image_config[0].working_directory == null
    error_message = "unset image_config attributes should remain null so the image's own settings apply."
  }
}

run "image_function_works_with_vpc_and_dead_letter_queue" {
  command = plan

  variables {
    function_name = "example-image-function"
    role          = "arn:aws:iam::123456789012:role/example-lambda-role"
    package_type  = "Image"
    image_uri     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/example:v1.0.0"
    architectures = ["x86_64"]
    memory_size   = 2048
    timeout       = 300
    vpc_config = {
      subnet_ids         = ["subnet-aaaaaaaa"]
      security_group_ids = ["sg-11111111"]
    }
    reserved_concurrent_executions = 2
  }

  assert {
    condition     = aws_lambda_function.lambda_function.memory_size == 2048
    error_message = "memory_size should be honored for image functions."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.vpc_config[0].subnet_ids == toset(["subnet-aaaaaaaa"])
    error_message = "vpc_config should still work for image functions."
  }

  assert {
    condition     = aws_lambda_function.lambda_function.reserved_concurrent_executions == 2
    error_message = "reserved_concurrent_executions should be honored for image functions."
  }
}

# Cross-variable preconditions on the resource (a variable validation block cannot reference other
# variables before OpenTofu/Terraform 1.9, and this module supports 1.3+).

run "rejects_image_package_type_without_image_uri" {
  command = plan

  variables {
    function_name = "example-image-function"
    role          = "arn:aws:iam::123456789012:role/example-lambda-role"
    package_type  = "Image"
    filename      = "function.zip"
  }

  expect_failures = [aws_lambda_function.lambda_function]
}

run "rejects_image_uri_without_image_package_type" {
  command = plan

  variables {
    function_name = "example-function"
    role          = "arn:aws:iam::123456789012:role/example-lambda-role"
    image_uri     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/example:v1.0.0"
  }

  expect_failures = [aws_lambda_function.lambda_function]
}

run "rejects_image_uri_with_explicit_zip_package_type" {
  command = plan

  variables {
    function_name = "example-function"
    role          = "arn:aws:iam::123456789012:role/example-lambda-role"
    package_type  = "Zip"
    image_uri     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/example:v1.0.0"
  }

  expect_failures = [aws_lambda_function.lambda_function]
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
