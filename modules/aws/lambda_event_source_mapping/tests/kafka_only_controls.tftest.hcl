mock_provider "aws" {}

variables {
  function_name    = "worker"
  event_source_arn = "arn:aws:sqs:us-east-1:123456789012:work"
}

run "rejects_sqs_error_count" {
  command = plan
  variables {
    metrics_config = { metrics = ["ErrorCount"] }
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_sqs_kafka_metrics" {
  command = plan
  variables {
    metrics_config = { metrics = ["KafkaMetrics"] }
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_kinesis_error_count" {
  command = plan
  variables {
    event_source_arn  = "arn:aws:kinesis:us-east-1:123456789012:stream/events"
    starting_position = "TRIM_HORIZON"
    metrics_config    = { metrics = ["ErrorCount"] }
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_kinesis_kafka_metrics" {
  command = plan
  variables {
    event_source_arn  = "arn:aws:kinesis:us-east-1:123456789012:stream/events"
    starting_position = "TRIM_HORIZON"
    metrics_config    = { metrics = ["KafkaMetrics"] }
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_dynamodb_error_count" {
  command = plan
  variables {
    event_source_arn  = "arn:aws:dynamodb:us-east-1:123456789012:table/events/stream/2026-01-01T00:00:00.000"
    starting_position = "TRIM_HORIZON"
    metrics_config    = { metrics = ["ErrorCount"] }
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_dynamodb_kafka_metrics" {
  command = plan
  variables {
    event_source_arn  = "arn:aws:dynamodb:us-east-1:123456789012:table/events/stream/2026-01-01T00:00:00.000"
    starting_position = "TRIM_HORIZON"
    metrics_config    = { metrics = ["KafkaMetrics"] }
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "rejects_sqs_poller_group_name" {
  command = plan
  variables {
    provisioned_poller_config = {
      minimum_pollers   = 2
      maximum_pollers   = 20
      poller_group_name = "workers"
    }
  }
  expect_failures = [aws_lambda_event_source_mapping.this]
}

run "sqs_event_count_and_poller_limits_remain_supported" {
  command = plan
  variables {
    metrics_config = { metrics = ["EventCount"] }
    provisioned_poller_config = {
      minimum_pollers = 2
      maximum_pollers = 20
    }
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.metrics_config[0].metrics == toset(["EventCount"]) && aws_lambda_event_source_mapping.this.provisioned_poller_config[0].minimum_pollers == 2 && aws_lambda_event_source_mapping.this.provisioned_poller_config[0].maximum_pollers == 20 && try(var.provisioned_poller_config.poller_group_name, null) == null
    error_message = "SQS must retain EventCount and exact poller limits without configuring a Kafka-only group."
  }
}

run "dynamodb_event_count_remains_supported" {
  command = plan
  variables {
    event_source_arn  = "arn:aws:dynamodb:us-east-1:123456789012:table/events/stream/2026-01-01T00:00:00.000"
    starting_position = "TRIM_HORIZON"
    metrics_config    = { metrics = ["EventCount"] }
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.metrics_config[0].metrics == toset(["EventCount"]) && aws_lambda_event_source_mapping.this.starting_position == "TRIM_HORIZON"
    error_message = "DynamoDB must retain exact EventCount and stream-position wiring."
  }
}

run "managed_kafka_all_metrics_and_named_pollers" {
  command = plan
  variables {
    event_source_arn = "arn:aws:kafka:us-east-1:123456789012:cluster/events/00000000-0000-0000-0000-000000000000-1"
    topics           = ["orders"]
    metrics_config   = { metrics = ["EventCount", "ErrorCount", "KafkaMetrics"] }
    provisioned_poller_config = {
      minimum_pollers   = 1
      maximum_pollers   = 20
      poller_group_name = "managed-workers"
    }
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.metrics_config[0].metrics == toset(["EventCount", "ErrorCount", "KafkaMetrics"]) && aws_lambda_event_source_mapping.this.provisioned_poller_config[0].poller_group_name == "managed-workers" && aws_lambda_event_source_mapping.this.provisioned_poller_config[0].minimum_pollers == 1 && aws_lambda_event_source_mapping.this.provisioned_poller_config[0].maximum_pollers == 20
    error_message = "Managed Kafka must forward all three metrics and the exact group and poller limits."
  }
}

run "self_managed_kafka_all_metrics_and_named_pollers" {
  command = plan
  variables {
    event_source_arn = null
    self_managed_event_source = {
      endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" }
    }
    topics         = ["orders"]
    metrics_config = { metrics = ["EventCount", "ErrorCount", "KafkaMetrics"] }
    provisioned_poller_config = {
      minimum_pollers   = 1
      maximum_pollers   = 20
      poller_group_name = "self-workers"
    }
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.metrics_config[0].metrics == toset(["EventCount", "ErrorCount", "KafkaMetrics"]) && aws_lambda_event_source_mapping.this.provisioned_poller_config[0].poller_group_name == "self-workers" && aws_lambda_event_source_mapping.this.provisioned_poller_config[0].minimum_pollers == 1 && aws_lambda_event_source_mapping.this.provisioned_poller_config[0].maximum_pollers == 20
    error_message = "Self-managed Kafka must forward all three metrics and the exact group and poller limits."
  }
}
