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



run "rejects_self_managed_kafka_event_source_config_access_enum" {
  command = plan
  variables {
    topics                                 = ["orders"]
    provisioned_poller_config              = { minimum_pollers = 1, maximum_pollers = 1 }
    event_source_arn                       = null
    self_managed_event_source              = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
    self_managed_kafka_event_source_config = { schema_registry_config = { access_config = [{ type = "VPC_SUBNET" }] } }
  }
  expect_failures = [var.self_managed_kafka_event_source_config]
}

run "rejects_self_managed_kafka_event_source_config_attribute_enum" {
  command = plan
  variables {
    topics                                 = ["orders"]
    provisioned_poller_config              = { minimum_pollers = 1, maximum_pollers = 1 }
    event_source_arn                       = null
    self_managed_event_source              = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
    self_managed_kafka_event_source_config = { schema_registry_config = { schema_validation_config = [{ attribute = "HEADER" }] } }
  }
  expect_failures = [var.self_managed_kafka_event_source_config]
}

run "rejects_no_source" {
  command = plan
  variables {
    event_source_arn = null
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_both_sources" {
  command = plan
  variables {
    topics                    = ["orders"]
    self_managed_event_source = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_fifo_batch" {
  command = plan
  variables {
    event_source_arn                   = "arn:aws:sqs:us-east-1:123456789012:work.fifo"
    batch_size                         = 11
    maximum_batching_window_in_seconds = 0
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_sqs_large_batch_no_window" {
  command = plan
  variables {
    batch_size = 11
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_sqs_large_batch_zero_window" {
  command = plan
  variables {
    batch_size                         = 11
    maximum_batching_window_in_seconds = 0
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_fifo_positive_window" {
  command = plan
  variables {
    event_source_arn                   = "arn:aws:sqs:us-east-1:123456789012:work.fifo"
    maximum_batching_window_in_seconds = 1
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_mq_partial_response" {
  command = plan
  variables {
    queues                  = ["orders"]
    event_source_arn        = "arn:aws:mq:us-east-1:123456789012:broker:events:b-00000000-0000-0000-0000-000000000000"
    function_response_types = ["ReportBatchItemFailures"]
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_documentdb_partial_response" {
  command = plan
  variables {
    event_source_arn        = "arn:aws:rds:us-east-1:123456789012:cluster:events"
    function_response_types = ["ReportBatchItemFailures"]
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}