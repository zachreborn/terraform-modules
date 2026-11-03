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



run "rejects_parallelization_factor_1" {
  command = plan
  variables {
    parallelization_factor = 11
  }
  expect_failures = [var.parallelization_factor]
}

run "rejects_parallelization_factor_2" {
  command = plan
  variables {
    parallelization_factor = 1.5
  }
  expect_failures = [var.parallelization_factor]
}

run "rejects_tumbling_window_in_seconds_0" {
  command = plan
  variables {
    tumbling_window_in_seconds = -1
  }
  expect_failures = [var.tumbling_window_in_seconds]
}

run "rejects_tumbling_window_in_seconds_1" {
  command = plan
  variables {
    tumbling_window_in_seconds = 901
  }
  expect_failures = [var.tumbling_window_in_seconds]
}

run "rejects_tumbling_window_in_seconds_2" {
  command = plan
  variables {
    tumbling_window_in_seconds = 0.5
  }
  expect_failures = [var.tumbling_window_in_seconds]
}

run "rejects_maximum_concurrency_0" {
  command = plan
  variables {
    scaling_config = { maximum_concurrency = 1 }
  }
  expect_failures = [var.scaling_config]
}

run "rejects_maximum_concurrency_1" {
  command = plan
  variables {
    scaling_config = { maximum_concurrency = 2.5 }
  }
  expect_failures = [var.scaling_config]
}

run "rejects_minimum_pollers_0" {
  command = plan
  variables {
    provisioned_poller_config = { minimum_pollers = 0 }
  }
  expect_failures = [var.provisioned_poller_config]
}

run "rejects_minimum_pollers_1" {
  command = plan
  variables {
    provisioned_poller_config = { minimum_pollers = 201 }
  }
  expect_failures = [var.provisioned_poller_config]
}

run "rejects_minimum_pollers_2" {
  command = plan
  variables {
    provisioned_poller_config = { minimum_pollers = 1.5 }
  }
  expect_failures = [var.provisioned_poller_config]
}