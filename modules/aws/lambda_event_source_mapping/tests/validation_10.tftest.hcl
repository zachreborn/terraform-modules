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



run "rejects_sqs_poller_scaling_conflict" {
  command = plan
  variables {
    provisioned_poller_config = { minimum_pollers = 2 }
    scaling_config            = { maximum_concurrency = 5 }
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_bisect_wrong_source" {
  command = plan
  variables {
    bisect_batch_on_function_error = false
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_record_age_wrong_source" {
  command = plan
  variables {
    maximum_record_age_in_seconds = -1
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_retry_wrong_source" {
  command = plan
  variables {
    maximum_retry_attempts = -1
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_destination_wrong_source" {
  command = plan
  variables {
    destination_config = {}
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_parallelization_wrong_source" {
  command = plan
  variables {
    parallelization_factor = 1
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_tumbling_wrong_source" {
  command = plan
  variables {
    tumbling_window_in_seconds = 0
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}
