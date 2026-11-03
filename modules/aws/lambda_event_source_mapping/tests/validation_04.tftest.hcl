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



run "rejects_maximum_pollers_0" {
  command = plan
  variables {
    provisioned_poller_config = { maximum_pollers = 0 }
  }
  expect_failures = [var.provisioned_poller_config]
}

run "rejects_maximum_pollers_1" {
  command = plan
  variables {
    provisioned_poller_config = { maximum_pollers = 2001 }
  }
  expect_failures = [var.provisioned_poller_config]
}

run "rejects_maximum_pollers_2" {
  command = plan
  variables {
    provisioned_poller_config = { maximum_pollers = 1.5 }
  }
  expect_failures = [var.provisioned_poller_config]
}

run "rejects_poller_group_name_0" {
  command = plan
  variables {
    provisioned_poller_config = { poller_group_name = "" }
  }
  expect_failures = [var.provisioned_poller_config]
}

run "rejects_poller_group_name_1" {
  command = plan
  variables {
    provisioned_poller_config = { poller_group_name = "ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg" }
  }
  expect_failures = [var.provisioned_poller_config]
}

run "rejects_poller_order" {
  command = plan
  variables {
    provisioned_poller_config = { minimum_pollers = 5, maximum_pollers = 4 }
  }
  expect_failures = [var.provisioned_poller_config]
}

run "rejects_queues_cardinality" {
  command = plan
  variables {
    queues = ["one", "two"]
  }
  expect_failures = [var.queues]
}

run "rejects_queues_empty" {
  command = plan
  variables {
    queues = [""]
  }
  expect_failures = [var.queues]
}

run "rejects_queues_length" {
  command = plan
  variables {
    queues = ["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"]
  }
  expect_failures = [var.queues]
}

run "rejects_queues_null" {
  command = plan
  variables {
    queues = [null]
  }
  expect_failures = [var.queues]
}