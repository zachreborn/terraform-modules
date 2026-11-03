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



run "rejects_starting_position_timestamp_0" {
  command = plan
  variables {
    starting_position_timestamp = "not-a-date"
  }
  expect_failures = [var.starting_position_timestamp]
}

run "rejects_maximum_record_age_in_seconds_0" {
  command = plan
  variables {
    maximum_record_age_in_seconds = -2
  }
  expect_failures = [var.maximum_record_age_in_seconds]
}

run "rejects_maximum_record_age_in_seconds_1" {
  command = plan
  variables {
    maximum_record_age_in_seconds = 0
  }
  expect_failures = [var.maximum_record_age_in_seconds]
}

run "rejects_maximum_record_age_in_seconds_2" {
  command = plan
  variables {
    maximum_record_age_in_seconds = 59
  }
  expect_failures = [var.maximum_record_age_in_seconds]
}

run "rejects_maximum_record_age_in_seconds_3" {
  command = plan
  variables {
    maximum_record_age_in_seconds = 604801
  }
  expect_failures = [var.maximum_record_age_in_seconds]
}

run "rejects_maximum_record_age_in_seconds_4" {
  command = plan
  variables {
    maximum_record_age_in_seconds = 60.5
  }
  expect_failures = [var.maximum_record_age_in_seconds]
}

run "rejects_maximum_retry_attempts_0" {
  command = plan
  variables {
    maximum_retry_attempts = -2
  }
  expect_failures = [var.maximum_retry_attempts]
}

run "rejects_maximum_retry_attempts_1" {
  command = plan
  variables {
    maximum_retry_attempts = 10001
  }
  expect_failures = [var.maximum_retry_attempts]
}

run "rejects_maximum_retry_attempts_2" {
  command = plan
  variables {
    maximum_retry_attempts = 0.5
  }
  expect_failures = [var.maximum_retry_attempts]
}

run "rejects_parallelization_factor_0" {
  command = plan
  variables {
    parallelization_factor = 0
  }
  expect_failures = [var.parallelization_factor]
}