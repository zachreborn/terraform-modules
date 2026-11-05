mock_provider "aws" {}

variables {
  function_name     = "worker"
  event_source_arn  = "arn:aws:kafka:us-east-1:123456789012:cluster/events/00000000-0000-0000-0000-000000000000-1"
  topics            = ["orders"]
  starting_position = "LATEST"
}

run "managed_kafka_partial_response_requires_provisioned_mode" {
  command = plan
  variables {
    function_response_types = ["ReportBatchItemFailures"]
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "self_kafka_partial_response_requires_provisioned_mode" {
  command = plan
  variables {
    event_source_arn          = null
    self_managed_event_source = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
    function_response_types   = ["ReportBatchItemFailures"]
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "managed_kafka_retry_limit_requires_provisioned_mode" {
  command = plan
  variables {
    maximum_retry_attempts = 3
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "self_kafka_retry_limit_requires_provisioned_mode" {
  command = plan
  variables {
    event_source_arn          = null
    self_managed_event_source = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
    maximum_retry_attempts    = 3
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "managed_kafka_record_age_requires_provisioned_mode" {
  command = plan
  variables {
    maximum_record_age_in_seconds = 60
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "self_kafka_record_age_requires_provisioned_mode" {
  command = plan
  variables {
    event_source_arn              = null
    self_managed_event_source     = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
    maximum_record_age_in_seconds = 60
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "managed_kafka_batch_splitting_requires_provisioned_mode" {
  command = plan
  variables {
    bisect_batch_on_function_error = true
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "self_kafka_batch_splitting_requires_provisioned_mode" {
  command = plan
  variables {
    event_source_arn               = null
    self_managed_event_source      = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
    bisect_batch_on_function_error = true
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "managed_kafka_registry_requires_provisioned_mode" {
  command = plan
  variables {
    amazon_managed_kafka_event_source_config = {
      schema_registry_config = {
        schema_registry_uri      = "https://registry.example.invalid"
        event_record_format      = "JSON"
        schema_validation_config = [{ attribute = "VALUE" }]
      }
    }
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "self_kafka_registry_requires_provisioned_mode" {
  command = plan
  variables {
    event_source_arn          = null
    self_managed_event_source = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
    self_managed_kafka_event_source_config = {
      schema_registry_config = {
        schema_registry_uri      = "https://registry.example.invalid"
        event_record_format      = "JSON"
        schema_validation_config = [{ attribute = "VALUE" }]
      }
    }
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "managed_kafka_requires_one_topic" {
  command = plan
  variables {
    topics = []
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "self_kafka_requires_one_topic" {
  command = plan
  variables {
    event_source_arn          = null
    self_managed_event_source = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
    topics                    = []
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "mq_requires_one_queue" {
  command = plan
  variables {
    event_source_arn  = "arn:aws:mq:us-east-1:123456789012:broker:events:b-00000000-0000-0000-0000-000000000000"
    topics            = []
    starting_position = ""
    queues            = []
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "managed_kafka_on_demand_destination_remains_supported" {
  command = plan
  variables {
    destination_config = {
      on_failure = { destination_arn = "arn:aws:sqs:us-east-1:123456789012:failures" }
    }
    bisect_batch_on_function_error = false
  }
  assert {
    condition     = length(aws_lambda_event_source_mapping.this.provisioned_poller_config) == 0 && aws_lambda_event_source_mapping.this.destination_config[0].on_failure[0].destination_arn == "arn:aws:sqs:us-east-1:123456789012:failures" && aws_lambda_event_source_mapping.this.bisect_batch_on_function_error == false && aws_lambda_event_source_mapping.this.topics == toset(["orders"])
    error_message = "On-demand managed Kafka must retain exact failure-destination wiring without enabling provisioned-only controls."
  }
}

run "self_kafka_on_demand_destination_remains_supported" {
  command = plan
  variables {
    event_source_arn          = null
    self_managed_event_source = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
    destination_config = {
      on_failure = { destination_arn = "arn:aws:sqs:us-east-1:123456789012:failures" }
    }
    bisect_batch_on_function_error = false
  }
  assert {
    condition     = length(aws_lambda_event_source_mapping.this.provisioned_poller_config) == 0 && aws_lambda_event_source_mapping.this.destination_config[0].on_failure[0].destination_arn == "arn:aws:sqs:us-east-1:123456789012:failures" && aws_lambda_event_source_mapping.this.bisect_batch_on_function_error == false && aws_lambda_event_source_mapping.this.topics == toset(["orders"])
    error_message = "On-demand self-managed Kafka must retain exact failure-destination wiring without enabling provisioned-only controls."
  }
}
