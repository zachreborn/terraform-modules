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



run "rejects_sqs_position" {
  command = plan
  variables {
    starting_position = "LATEST"
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_sqs_timestamp" {
  command = plan
  variables {
    starting_position_timestamp = "2026-01-01T00:00:00Z"
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_mq_position" {
  command = plan
  variables {
    queues            = ["orders"]
    event_source_arn  = "arn:aws:mq:us-east-1:123456789012:broker:events:b-00000000-0000-0000-0000-000000000000"
    starting_position = "LATEST"
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_kinesis_missing_position" {
  command = plan
  variables {
    event_source_arn = "arn:aws:kinesis:us-east-1:123456789012:stream/events"
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_dynamodb_missing_position" {
  command = plan
  variables {
    event_source_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/events/stream/2026-01-01T00:00:00.000"
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_timestamp_without_at_timestamp" {
  command = plan
  variables {
    event_source_arn            = "arn:aws:kinesis:us-east-1:123456789012:stream/events"
    starting_position           = "LATEST"
    starting_position_timestamp = "2026-01-01T00:00:00Z"
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_at_timestamp_without_timestamp" {
  command = plan
  variables {
    event_source_arn  = "arn:aws:kinesis:us-east-1:123456789012:stream/events"
    starting_position = "AT_TIMESTAMP"
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_dynamodb_at_timestamp" {
  command = plan
  variables {
    event_source_arn            = "arn:aws:dynamodb:us-east-1:123456789012:table/events/stream/2026-01-01T00:00:00.000"
    starting_position           = "AT_TIMESTAMP"
    starting_position_timestamp = "2026-01-01T00:00:00Z"
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_managed_kafka_wrong_source" {
  command = plan
  variables {
    amazon_managed_kafka_event_source_config = {}
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_managed_kafka_with_self_source" {
  command = plan
  variables {
    topics                                   = ["orders"]
    event_source_arn                         = null
    self_managed_event_source                = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
    amazon_managed_kafka_event_source_config = {}
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}