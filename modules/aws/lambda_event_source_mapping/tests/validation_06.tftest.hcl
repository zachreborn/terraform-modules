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



run "rejects_metrics_enum" {
  command = plan
  variables {
    metrics_config = { metrics = ["BadMetric"] }
  }
  expect_failures = [var.metrics_config]
}

run "rejects_document_full_document" {
  command = plan
  variables {
    document_db_event_source_config = { database_name = "app", full_document = "Unknown" }
  }
  expect_failures = [var.document_db_event_source_config]
}

run "rejects_amazon_managed_kafka_event_source_config_group_empty" {
  command = plan
  variables {
    amazon_managed_kafka_event_source_config = { consumer_group_id = "" }
  }
  expect_failures = [var.amazon_managed_kafka_event_source_config]
}

run "rejects_amazon_managed_kafka_event_source_config_group_long" {
  command = plan
  variables {
    amazon_managed_kafka_event_source_config = { consumer_group_id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" }
  }
  expect_failures = [var.amazon_managed_kafka_event_source_config]
}

run "rejects_amazon_managed_kafka_event_source_config_format" {
  command = plan
  variables {
    topics                                   = ["orders"]
    provisioned_poller_config                = { minimum_pollers = 1, maximum_pollers = 1 }
    event_source_arn                         = "arn:aws:kafka:us-east-1:123456789012:cluster/events/00000000-0000-0000-0000-000000000000-1"
    amazon_managed_kafka_event_source_config = { schema_registry_config = { event_record_format = "XML" } }
  }
  expect_failures = [var.amazon_managed_kafka_event_source_config]
}

run "rejects_amazon_managed_kafka_event_source_config_access_enum" {
  command = plan
  variables {
    topics                                   = ["orders"]
    provisioned_poller_config                = { minimum_pollers = 1, maximum_pollers = 1 }
    event_source_arn                         = "arn:aws:kafka:us-east-1:123456789012:cluster/events/00000000-0000-0000-0000-000000000000-1"
    amazon_managed_kafka_event_source_config = { schema_registry_config = { access_config = [{ type = "VPC_SUBNET" }] } }
  }
  expect_failures = [var.amazon_managed_kafka_event_source_config]
}

run "rejects_amazon_managed_kafka_event_source_config_attribute_enum" {
  command = plan
  variables {
    topics                                   = ["orders"]
    provisioned_poller_config                = { minimum_pollers = 1, maximum_pollers = 1 }
    event_source_arn                         = "arn:aws:kafka:us-east-1:123456789012:cluster/events/00000000-0000-0000-0000-000000000000-1"
    amazon_managed_kafka_event_source_config = { schema_registry_config = { schema_validation_config = [{ attribute = "HEADER" }] } }
  }
  expect_failures = [var.amazon_managed_kafka_event_source_config]
}

run "rejects_self_managed_kafka_event_source_config_group_empty" {
  command = plan
  variables {
    self_managed_kafka_event_source_config = { consumer_group_id = "" }
  }
  expect_failures = [var.self_managed_kafka_event_source_config]
}

run "rejects_self_managed_kafka_event_source_config_group_long" {
  command = plan
  variables {
    self_managed_kafka_event_source_config = { consumer_group_id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" }
  }
  expect_failures = [var.self_managed_kafka_event_source_config]
}

run "rejects_self_managed_kafka_event_source_config_format" {
  command = plan
  variables {
    topics                                 = ["orders"]
    provisioned_poller_config              = { minimum_pollers = 1, maximum_pollers = 1 }
    event_source_arn                       = null
    self_managed_event_source              = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
    self_managed_kafka_event_source_config = { schema_registry_config = { event_record_format = "XML" } }
  }
  expect_failures = [var.self_managed_kafka_event_source_config]
}