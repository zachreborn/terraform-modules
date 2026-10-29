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

run "rejects_batch_size_0" {
  command = plan
  variables {
    batch_size = "garbage"
  }
  expect_failures = [var.batch_size]
}

run "rejects_batch_size_1" {
  command = plan
  variables {
    batch_size = "1.5"
  }
  expect_failures = [var.batch_size]
}

run "rejects_batch_size_2" {
  command = plan
  variables {
    batch_size = "0"
  }
  expect_failures = [var.batch_size]
}

run "rejects_batch_size_3" {
  command = plan
  variables {
    batch_size = "10001"
  }
  expect_failures = [var.batch_size]
}

run "rejects_enabled_0" {
  command = plan
  variables {
    enabled = "yes"
  }
  expect_failures = [var.enabled]
}

run "rejects_function_response_types_0" {
  command = plan
  variables {
    function_response_types = ["Unknown"]
  }
  expect_failures = [var.function_response_types]
}

run "rejects_maximum_batching_window_in_seconds_0" {
  command = plan
  variables {
    maximum_batching_window_in_seconds = -1
  }
  expect_failures = [var.maximum_batching_window_in_seconds]
}

run "rejects_maximum_batching_window_in_seconds_1" {
  command = plan
  variables {
    maximum_batching_window_in_seconds = 301
  }
  expect_failures = [var.maximum_batching_window_in_seconds]
}

run "rejects_maximum_batching_window_in_seconds_2" {
  command = plan
  variables {
    maximum_batching_window_in_seconds = 0.5
  }
  expect_failures = [var.maximum_batching_window_in_seconds]
}

run "rejects_starting_position_0" {
  command = plan
  variables {
    starting_position = "FIRST"
  }
  expect_failures = [var.starting_position]
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

run "rejects_topics_cardinality" {
  command = plan
  variables {
    topics = ["one", "two"]
  }
  expect_failures = [var.topics]
}

run "rejects_topics_empty" {
  command = plan
  variables {
    topics = [""]
  }
  expect_failures = [var.topics]
}

run "rejects_topics_length" {
  command = plan
  variables {
    topics = ["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"]
  }
  expect_failures = [var.topics]
}

run "rejects_topics_null" {
  command = plan
  variables {
    topics = [null]
  }
  expect_failures = [var.topics]
}

run "rejects_source_access_count" {
  command = plan
  variables {
    source_access_configuration = [{ type = "VPC_SUBNET", uri = "subnet:subnet-00000000" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000001" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000002" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000003" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000004" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000005" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000006" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000007" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000008" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000009" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000010" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000011" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000012" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000013" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000014" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000015" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000016" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000017" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000018" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000019" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000020" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000021" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000022" }]
  }
  expect_failures = [var.source_access_configuration]
}

run "rejects_source_access_enum" {
  command = plan
  variables {
    source_access_configuration = [{ type = "BAD", uri = "fake" }]
  }
  expect_failures = [var.source_access_configuration]
}

run "rejects_filter_count" {
  command = plan
  variables {
    filter_criteria = { filter = [{ pattern = "{\"body\": {\"n\": [0]}}" }, { pattern = "{\"body\": {\"n\": [1]}}" }, { pattern = "{\"body\": {\"n\": [2]}}" }, { pattern = "{\"body\": {\"n\": [3]}}" }, { pattern = "{\"body\": {\"n\": [4]}}" }, { pattern = "{\"body\": {\"n\": [5]}}" }, { pattern = "{\"body\": {\"n\": [6]}}" }, { pattern = "{\"body\": {\"n\": [7]}}" }, { pattern = "{\"body\": {\"n\": [8]}}" }, { pattern = "{\"body\": {\"n\": [9]}}" }, { pattern = "{\"body\": {\"n\": [10]}}" }] }
  }
  expect_failures = [var.filter_criteria]
}

run "rejects_filter_json" {
  command = plan
  variables {
    filter_criteria = { filter = [{ pattern = "{broken" }] }
  }
  expect_failures = [var.filter_criteria]
}

run "rejects_filter_length" {
  command = plan
  variables {
    filter_criteria = { filter = [{ pattern = "{\"x\": \"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"}" }] }
  }
  expect_failures = [var.filter_criteria]
}

run "rejects_metrics_empty" {
  command = plan
  variables {
    metrics_config = { metrics = [] }
  }
  expect_failures = [var.metrics_config]
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
