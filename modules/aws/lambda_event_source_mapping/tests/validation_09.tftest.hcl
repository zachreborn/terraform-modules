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



run "rejects_both_kafka_configs" {
  command = plan
  variables {
    topics                                   = ["orders"]
    event_source_arn                         = "arn:aws:kafka:us-east-1:123456789012:cluster/events/00000000-0000-0000-0000-000000000000-1"
    amazon_managed_kafka_event_source_config = {}
    self_managed_kafka_event_source_config   = {}
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_self_kafka_with_arn" {
  command = plan
  variables {
    self_managed_kafka_event_source_config = {}
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_self_kafka_without_self_source" {
  command = plan
  variables {
    event_source_arn                       = null
    self_managed_kafka_event_source_config = {}
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_topics_wrong_source" {
  command = plan
  variables {
    topics = ["orders"]
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_queues_wrong_source" {
  command = plan
  variables {
    queues = ["orders"]
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_scaling_wrong_source" {
  command = plan
  variables {
    topics           = ["orders"]
    event_source_arn = "arn:aws:kafka:us-east-1:123456789012:cluster/events/00000000-0000-0000-0000-000000000000-1"
    scaling_config   = {}
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_document_config_wrong_source" {
  command = plan
  variables {
    document_db_event_source_config = { database_name = "app" }
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_pollers_wrong_source" {
  command = plan
  variables {
    queues                    = ["orders"]
    event_source_arn          = "arn:aws:mq:us-east-1:123456789012:broker:events:b-00000000-0000-0000-0000-000000000000"
    provisioned_poller_config = {}
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_sqs_poller_minimum" {
  command = plan
  variables {
    provisioned_poller_config = { minimum_pollers = 1 }
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_sqs_poller_maximum" {
  command = plan
  variables {
    provisioned_poller_config = { maximum_pollers = 1 }
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}