# Offline only: mock computed attributes, never configured inputs.
mock_provider "aws" {
  mock_resource "aws_lambda_event_source_mapping" {
    defaults = {
      id                      = "00000000-0000-0000-0000-000000000537"
      uuid                    = "00000000-0000-0000-0000-000000000537"
      arn                     = "arn:aws:lambda:us-east-1:123456789012:event-source-mapping:00000000-0000-0000-0000-000000000537"
      function_arn            = "arn:aws:lambda:us-east-1:123456789012:function:worker"
      state                   = "Enabled"
      state_transition_reason = "USER_INITIATED"
      last_modified           = "2026-01-01T00:00:00Z"
      last_processing_result  = "OK"
      tags_all                = { Name = "worker" }
    }
  }
}

variables {
  function_name    = "worker"
  event_source_arn = "arn:aws:sqs:us-east-1:123456789012:work"
}

run "rejects_batch_size_0" {
  command = plan
  variables {
    batch_size = "garbage"
  }
  expect_failures = [var.batch_size]
}

run "rejects_batch_size_1" {
  command = plan
  variables {
    batch_size = "1.5"
  }
  expect_failures = [var.batch_size]
}

run "rejects_batch_size_2" {
  command = plan
  variables {
    batch_size = "0"
  }
  expect_failures = [var.batch_size]
}

run "rejects_batch_size_3" {
  command = plan
  variables {
    batch_size = "10001"
  }
  expect_failures = [var.batch_size]
}

run "rejects_enabled_0" {
  command = plan
  variables {
    enabled = "yes"
  }
  expect_failures = [var.enabled]
}

run "rejects_function_response_types_0" {
  command = plan
  variables {
    function_response_types = ["Unknown"]
  }
  expect_failures = [var.function_response_types]
}

run "rejects_maximum_batching_window_in_seconds_0" {
  command = plan
  variables {
    maximum_batching_window_in_seconds = -1
  }
  expect_failures = [var.maximum_batching_window_in_seconds]
}

run "rejects_maximum_batching_window_in_seconds_1" {
  command = plan
  variables {
    maximum_batching_window_in_seconds = 301
  }
  expect_failures = [var.maximum_batching_window_in_seconds]
}

run "rejects_maximum_batching_window_in_seconds_2" {
  command = plan
  variables {
    maximum_batching_window_in_seconds = 0.5
  }
  expect_failures = [var.maximum_batching_window_in_seconds]
}

run "rejects_starting_position_0" {
  command = plan
  variables {
    starting_position = "FIRST"
  }
  expect_failures = [var.starting_position]
}