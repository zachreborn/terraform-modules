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

run "legacy_sqs_defaults" {
  command = plan
  assert {
    condition     = output.batch_size == 10
    error_message = "legacy_sqs_defaults: exact resource/output wiring changed."
  }
  assert {
    condition     = output.enabled == true
    error_message = "legacy_sqs_defaults: exact resource/output wiring changed."
  }
  assert {
    condition     = output.function_response_types == setsubtract(toset(["ReportBatchItemFailures"]), toset(["ReportBatchItemFailures"]))
    error_message = "legacy_sqs_defaults: exact resource/output wiring changed."
  }
  assert {
    condition     = output.maximum_batching_window_in_seconds == null
    error_message = "legacy_sqs_defaults: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.function_name == "worker"
    error_message = "legacy_sqs_defaults: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.event_source_arn == "arn:aws:sqs:us-east-1:123456789012:work"
    error_message = "legacy_sqs_defaults: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.starting_position == null && aws_lambda_event_source_mapping.this.starting_position_timestamp == null
    error_message = "legacy_sqs_defaults: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.tags == tomap({ Name = "worker" })
    error_message = "legacy_sqs_defaults: exact resource/output wiring changed."
  }
  assert {
    condition     = length(aws_lambda_event_source_mapping.this.destination_config) == 0 && length(aws_lambda_event_source_mapping.this.document_db_event_source_config) == 0 && length(aws_lambda_event_source_mapping.this.filter_criteria) == 0 && length(aws_lambda_event_source_mapping.this.metrics_config) == 0 && length(aws_lambda_event_source_mapping.this.scaling_config) == 0 && length(aws_lambda_event_source_mapping.this.provisioned_poller_config) == 0 && length(aws_lambda_event_source_mapping.this.self_managed_event_source) == 0 && length(aws_lambda_event_source_mapping.this.source_access_configuration) == 0
    error_message = "legacy_sqs_defaults: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.use_resource_timeout_for_propagation == false && aws_lambda_event_source_mapping.this.timeouts == null
    error_message = "legacy_sqs_defaults: exact resource/output wiring changed."
  }
}

run "required_sqs_adoption" {
  command = plan
  variables {
    batch_size                         = 10
    enabled                            = true
    maximum_batching_window_in_seconds = 5
    function_response_types            = ["ReportBatchItemFailures"]
  }
  assert {
    condition     = output.batch_size == 10 && output.enabled == true
    error_message = "required_sqs_adoption: exact resource/output wiring changed."
  }
  assert {
    condition     = output.function_response_types == toset(["ReportBatchItemFailures"])
    error_message = "required_sqs_adoption: exact resource/output wiring changed."
  }
  assert {
    condition     = output.maximum_batching_window_in_seconds == 5
    error_message = "required_sqs_adoption: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.event_source_arn == "arn:aws:sqs:us-east-1:123456789012:work" && aws_lambda_event_source_mapping.this.function_name == "worker"
    error_message = "required_sqs_adoption: exact resource/output wiring changed."
  }
}

run "disabled_string_zero_window" {
  command = plan
  variables {
    enabled                            = "false"
    maximum_batching_window_in_seconds = 0
  }
  assert {
    condition     = output.enabled == false
    error_message = "disabled_string_zero_window: exact resource/output wiring changed."
  }
  assert {
    condition     = output.maximum_batching_window_in_seconds == 0
    error_message = "disabled_string_zero_window: exact resource/output wiring changed."
  }
}

run "fifo_sqs" {
  command = plan
  variables {
    event_source_arn                   = "arn:aws:sqs:us-east-1:123456789012:work.fifo"
    maximum_batching_window_in_seconds = 0
  }
  assert {
    condition     = output.batch_size == 10
    error_message = "fifo_sqs: exact resource/output wiring changed."
  }
  assert {
    condition     = output.maximum_batching_window_in_seconds == 0
    error_message = "fifo_sqs: exact resource/output wiring changed."
  }
}

run "standard_sqs_large_batch" {
  command = plan
  variables {
    batch_size                         = "10000"
    maximum_batching_window_in_seconds = 300
    scaling_config                     = { maximum_concurrency = 2000 }
  }
  assert {
    condition     = output.batch_size == 10000
    error_message = "standard_sqs_large_batch: exact resource/output wiring changed."
  }
  assert {
    condition     = output.maximum_batching_window_in_seconds == 300
    error_message = "standard_sqs_large_batch: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.scaling_config[0].maximum_concurrency == 2000
    error_message = "standard_sqs_large_batch: exact resource/output wiring changed."
  }
}

run "clear_sqs_scaling" {
  command = plan
  variables {
    scaling_config = {}
  }
  assert {
    condition     = length(aws_lambda_event_source_mapping.this.scaling_config) == 1 && aws_lambda_event_source_mapping.this.scaling_config[0].maximum_concurrency == null
    error_message = "clear_sqs_scaling: exact resource/output wiring changed."
  }
}

run "sqs_provisioned_pollers" {
  command = plan
  variables {
    provisioned_poller_config = { minimum_pollers = 2, maximum_pollers = 2000 }
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.provisioned_poller_config[0].minimum_pollers == 2 && aws_lambda_event_source_mapping.this.provisioned_poller_config[0].maximum_pollers == 2000 && try(var.provisioned_poller_config.poller_group_name, null) == null
    error_message = "sqs_provisioned_pollers: exact resource/output wiring changed."
  }
}

run "kinesis_optional_controls" {
  command = plan
  variables {
    event_source_arn                     = "arn:aws:kinesis:us-east-1:123456789012:stream/events"
    starting_position                    = "AT_TIMESTAMP"
    starting_position_timestamp          = "2026-01-01T00:00:00Z"
    batch_size                           = 100
    bisect_batch_on_function_error       = true
    maximum_record_age_in_seconds        = 60
    maximum_retry_attempts               = 0
    parallelization_factor               = 10
    tumbling_window_in_seconds           = 900
    destination_config                   = { on_failure = { destination_arn = "arn:aws:sqs:us-east-1:123456789012:work" } }
    metrics_config                       = { metrics = ["EventCount"] }
    kms_key_arn                          = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
    filter_criteria                      = { filter = [{ pattern = "{\"data\":{\"kind\":[\"created\"]}}" }] }
    region                               = "us-west-2"
    tags                                 = { Name = "override", Team = "platform" }
    use_resource_timeout_for_propagation = true
    timeouts                             = { create = "15m", update = "12m", delete = "7m" }
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.starting_position == "AT_TIMESTAMP" && aws_lambda_event_source_mapping.this.starting_position_timestamp == "2026-01-01T00:00:00Z"
    error_message = "kinesis_optional_controls: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.bisect_batch_on_function_error == true && aws_lambda_event_source_mapping.this.maximum_record_age_in_seconds == 60 && aws_lambda_event_source_mapping.this.maximum_retry_attempts == 0
    error_message = "kinesis_optional_controls: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.parallelization_factor == 10 && aws_lambda_event_source_mapping.this.tumbling_window_in_seconds == 900
    error_message = "kinesis_optional_controls: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.destination_config[0].on_failure[0].destination_arn == "arn:aws:sqs:us-east-1:123456789012:work"
    error_message = "kinesis_optional_controls: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.metrics_config[0].metrics == toset(["EventCount"])
    error_message = "kinesis_optional_controls: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000000"
    error_message = "kinesis_optional_controls: exact resource/output wiring changed."
  }
  assert {
    condition     = one(aws_lambda_event_source_mapping.this.filter_criteria[0].filter).pattern == jsonencode({ data = { kind = ["created"] } })
    error_message = "kinesis_optional_controls: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.region == "us-west-2" && aws_lambda_event_source_mapping.this.tags == tomap({ Name = "override", Team = "platform" })
    error_message = "kinesis_optional_controls: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.timeouts.create == "15m" && aws_lambda_event_source_mapping.this.timeouts.update == "12m" && aws_lambda_event_source_mapping.this.timeouts.delete == "7m" && aws_lambda_event_source_mapping.this.use_resource_timeout_for_propagation == true
    error_message = "kinesis_optional_controls: exact resource/output wiring changed."
  }
}

run "dynamodb_legacy_stream_batch" {
  command = plan
  variables {
    event_source_arn   = "arn:aws:dynamodb:us-east-1:123456789012:table/events/stream/2026-01-01T00:00:00.000"
    starting_position  = "TRIM_HORIZON"
    batch_size         = 100
    destination_config = {}
    filter_criteria    = {}
  }
  assert {
    condition     = output.batch_size == 100 && output.maximum_batching_window_in_seconds == null
    error_message = "dynamodb_legacy_stream_batch: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.starting_position == "TRIM_HORIZON"
    error_message = "dynamodb_legacy_stream_batch: exact resource/output wiring changed."
  }
  assert {
    condition     = length(aws_lambda_event_source_mapping.this.destination_config[0].on_failure) == 0 && length(aws_lambda_event_source_mapping.this.filter_criteria[0].filter) == 0
    error_message = "dynamodb_legacy_stream_batch: exact resource/output wiring changed."
  }
}

run "managed_kafka_full" {
  command = plan
  variables {
    event_source_arn                         = "arn:aws:kafka:us-east-1:123456789012:cluster/events/00000000-0000-0000-0000-000000000000-1"
    topics                                   = ["orders"]
    starting_position                        = "AT_TIMESTAMP"
    starting_position_timestamp              = "2026-01-01T00:00:00Z"
    amazon_managed_kafka_event_source_config = { consumer_group_id = "workers", schema_registry_config = { access_config = [{ type = "BASIC_AUTH", uri = "arn:aws:secretsmanager:us-east-1:123456789012:secret:fake-auth" }], event_record_format = "JSON", schema_registry_uri = "https://registry.example.invalid", schema_validation_config = [{ attribute = "KEY" }, { attribute = "VALUE" }] } }
    source_access_configuration              = [{ type = "BASIC_AUTH", uri = "arn:aws:secretsmanager:us-east-1:123456789012:secret:fake-auth" }]
    function_response_types                  = ["ReportBatchItemFailures"]
    maximum_record_age_in_seconds            = -1
    maximum_retry_attempts                   = 10000
    bisect_batch_on_function_error           = true
    destination_config                       = { on_failure = { destination_arn = "arn:aws:sqs:us-east-1:123456789012:work" } }
    metrics_config                           = { metrics = ["KafkaMetrics"] }
    provisioned_poller_config                = { minimum_pollers = 1, maximum_pollers = 2000, poller_group_name = "gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg" }
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.topics == toset(["orders"])
    error_message = "managed_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.amazon_managed_kafka_event_source_config[0].consumer_group_id == "workers"
    error_message = "managed_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.amazon_managed_kafka_event_source_config[0].schema_registry_config[0].event_record_format == "JSON"
    error_message = "managed_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.amazon_managed_kafka_event_source_config[0].schema_registry_config[0].schema_registry_uri == "https://registry.example.invalid"
    error_message = "managed_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = one(aws_lambda_event_source_mapping.this.amazon_managed_kafka_event_source_config[0].schema_registry_config[0].access_config).type == "BASIC_AUTH" && one(aws_lambda_event_source_mapping.this.amazon_managed_kafka_event_source_config[0].schema_registry_config[0].access_config).uri == "arn:aws:secretsmanager:us-east-1:123456789012:secret:fake-auth"
    error_message = "managed_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = toset([for c in aws_lambda_event_source_mapping.this.amazon_managed_kafka_event_source_config[0].schema_registry_config[0].schema_validation_config : c.attribute]) == toset(["KEY", "VALUE"])
    error_message = "managed_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = one(aws_lambda_event_source_mapping.this.source_access_configuration).uri == "arn:aws:secretsmanager:us-east-1:123456789012:secret:fake-auth"
    error_message = "managed_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.provisioned_poller_config[0].minimum_pollers == 1 && aws_lambda_event_source_mapping.this.provisioned_poller_config[0].maximum_pollers == 2000
    error_message = "managed_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.maximum_retry_attempts == 10000 && aws_lambda_event_source_mapping.this.maximum_record_age_in_seconds == -1 && aws_lambda_event_source_mapping.this.bisect_batch_on_function_error == true
    error_message = "managed_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = output.function_response_types == toset(["ReportBatchItemFailures"])
    error_message = "managed_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = output.event_source_arn == "arn:aws:kafka:us-east-1:123456789012:cluster/events/00000000-0000-0000-0000-000000000000-1"
    error_message = "managed_kafka_full: exact resource/output wiring changed."
  }
}

run "managed_kafka_without_registry" {
  command = plan
  variables {
    event_source_arn                         = "arn:aws:kafka:us-east-1:123456789012:cluster/events/00000000-0000-0000-0000-000000000000-1"
    amazon_managed_kafka_event_source_config = { consumer_group_id = "x" }
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.amazon_managed_kafka_event_source_config[0].consumer_group_id == "x" && length(aws_lambda_event_source_mapping.this.amazon_managed_kafka_event_source_config[0].schema_registry_config) == 0
    error_message = "managed_kafka_without_registry: exact resource/output wiring changed."
  }
}

run "managed_kafka_empty_registry" {
  command = plan
  variables {
    event_source_arn                         = "arn:aws:kafka:us-east-1:123456789012:cluster/events/00000000-0000-0000-0000-000000000000-1"
    amazon_managed_kafka_event_source_config = { schema_registry_config = {} }
  }
  assert {
    condition     = length(aws_lambda_event_source_mapping.this.amazon_managed_kafka_event_source_config[0].schema_registry_config[0].access_config) == 0 && length(aws_lambda_event_source_mapping.this.amazon_managed_kafka_event_source_config[0].schema_registry_config[0].schema_validation_config) == 0
    error_message = "managed_kafka_empty_registry: exact resource/output wiring changed."
  }
}

run "self_kafka_full" {
  command = plan
  variables {
    event_source_arn                       = null
    topics                                 = ["orders"]
    starting_position                      = "AT_TIMESTAMP"
    starting_position_timestamp            = "2026-01-01T00:00:00Z"
    self_managed_kafka_event_source_config = { consumer_group_id = "workers", schema_registry_config = { access_config = [{ type = "BASIC_AUTH", uri = "arn:aws:secretsmanager:us-east-1:123456789012:secret:fake-auth" }], event_record_format = "JSON", schema_registry_uri = "https://registry.example.invalid", schema_validation_config = [{ attribute = "KEY" }, { attribute = "VALUE" }] } }
    source_access_configuration            = [{ type = "BASIC_AUTH", uri = "arn:aws:secretsmanager:us-east-1:123456789012:secret:fake-auth" }]
    function_response_types                = ["ReportBatchItemFailures"]
    maximum_record_age_in_seconds          = -1
    maximum_retry_attempts                 = 10000
    bisect_batch_on_function_error         = true
    destination_config                     = { on_failure = { destination_arn = "arn:aws:sqs:us-east-1:123456789012:work" } }
    metrics_config                         = { metrics = ["KafkaMetrics"] }
    provisioned_poller_config              = { minimum_pollers = 1, maximum_pollers = 2000, poller_group_name = "gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg" }
    self_managed_event_source              = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.topics == toset(["orders"])
    error_message = "self_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.self_managed_kafka_event_source_config[0].consumer_group_id == "workers"
    error_message = "self_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.self_managed_kafka_event_source_config[0].schema_registry_config[0].event_record_format == "JSON"
    error_message = "self_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.self_managed_kafka_event_source_config[0].schema_registry_config[0].schema_registry_uri == "https://registry.example.invalid"
    error_message = "self_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = one(aws_lambda_event_source_mapping.this.self_managed_kafka_event_source_config[0].schema_registry_config[0].access_config).type == "BASIC_AUTH" && one(aws_lambda_event_source_mapping.this.self_managed_kafka_event_source_config[0].schema_registry_config[0].access_config).uri == "arn:aws:secretsmanager:us-east-1:123456789012:secret:fake-auth"
    error_message = "self_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = toset([for c in aws_lambda_event_source_mapping.this.self_managed_kafka_event_source_config[0].schema_registry_config[0].schema_validation_config : c.attribute]) == toset(["KEY", "VALUE"])
    error_message = "self_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = one(aws_lambda_event_source_mapping.this.source_access_configuration).uri == "arn:aws:secretsmanager:us-east-1:123456789012:secret:fake-auth"
    error_message = "self_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.provisioned_poller_config[0].minimum_pollers == 1 && aws_lambda_event_source_mapping.this.provisioned_poller_config[0].maximum_pollers == 2000
    error_message = "self_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.maximum_retry_attempts == 10000 && aws_lambda_event_source_mapping.this.maximum_record_age_in_seconds == -1 && aws_lambda_event_source_mapping.this.bisect_batch_on_function_error == true
    error_message = "self_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = output.function_response_types == toset(["ReportBatchItemFailures"])
    error_message = "self_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = output.event_source_arn == null
    error_message = "self_kafka_full: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.self_managed_event_source[0].endpoints == tomap({ KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" })
    error_message = "self_kafka_full: exact resource/output wiring changed."
  }
}

run "self_kafka_without_registry" {
  command = plan
  variables {
    event_source_arn                       = null
    self_managed_kafka_event_source_config = { consumer_group_id = "x" }
    self_managed_event_source              = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.self_managed_kafka_event_source_config[0].consumer_group_id == "x" && length(aws_lambda_event_source_mapping.this.self_managed_kafka_event_source_config[0].schema_registry_config) == 0
    error_message = "self_kafka_without_registry: exact resource/output wiring changed."
  }
}

run "self_kafka_empty_registry" {
  command = plan
  variables {
    event_source_arn                       = null
    self_managed_kafka_event_source_config = { schema_registry_config = {} }
    self_managed_event_source              = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
  }
  assert {
    condition     = length(aws_lambda_event_source_mapping.this.self_managed_kafka_event_source_config[0].schema_registry_config[0].access_config) == 0 && length(aws_lambda_event_source_mapping.this.self_managed_kafka_event_source_config[0].schema_registry_config[0].schema_validation_config) == 0
    error_message = "self_kafka_empty_registry: exact resource/output wiring changed."
  }
}

run "mq" {
  command = plan
  variables {
    event_source_arn                   = "arn:aws:mq:us-east-1:123456789012:broker:events:b-00000000-0000-0000-0000-000000000000"
    queues                             = ["orders"]
    source_access_configuration        = [{ type = "BASIC_AUTH", uri = "arn:aws:secretsmanager:us-east-1:123456789012:secret:fake-auth" }]
    maximum_batching_window_in_seconds = 1
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.queues == tolist(["orders"])
    error_message = "mq: exact resource/output wiring changed."
  }
  assert {
    condition     = output.maximum_batching_window_in_seconds == 1
    error_message = "mq: exact resource/output wiring changed."
  }
}

run "documentdb_default" {
  command = plan
  variables {
    event_source_arn                = "arn:aws:rds:us-east-1:123456789012:cluster:events"
    starting_position               = "LATEST"
    document_db_event_source_config = { database_name = "app", collection_name = "orders", full_document = "Default" }
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.document_db_event_source_config[0].database_name == "app" && aws_lambda_event_source_mapping.this.document_db_event_source_config[0].collection_name == "orders" && aws_lambda_event_source_mapping.this.document_db_event_source_config[0].full_document == "Default"
    error_message = "documentdb_default: exact resource/output wiring changed."
  }
}

run "documentdb_updatelookup" {
  command = plan
  variables {
    event_source_arn                = "arn:aws:rds:us-east-1:123456789012:cluster:events"
    starting_position               = "LATEST"
    document_db_event_source_config = { database_name = "app", collection_name = "orders", full_document = "UpdateLookup" }
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.document_db_event_source_config[0].database_name == "app" && aws_lambda_event_source_mapping.this.document_db_event_source_config[0].collection_name == "orders" && aws_lambda_event_source_mapping.this.document_db_event_source_config[0].full_document == "UpdateLookup"
    error_message = "documentdb_updatelookup: exact resource/output wiring changed."
  }
}

run "raised_filter_quota_6" {
  command = plan
  variables {
    filter_criteria = { filter = [{ pattern = "{\"body\": {\"n\": [0]}}" }, { pattern = "{\"body\": {\"n\": [1]}}" }, { pattern = "{\"body\": {\"n\": [2]}}" }, { pattern = "{\"body\": {\"n\": [3]}}" }, { pattern = "{\"body\": {\"n\": [4]}}" }, { pattern = "{\"body\": {\"n\": [5]}}" }] }
  }
  assert {
    condition     = length(aws_lambda_event_source_mapping.this.filter_criteria[0].filter) == 6
    error_message = "raised_filter_quota_6: exact resource/output wiring changed."
  }
}

run "raised_filter_quota_7" {
  command = plan
  variables {
    filter_criteria = { filter = [{ pattern = "{\"body\": {\"n\": [0]}}" }, { pattern = "{\"body\": {\"n\": [1]}}" }, { pattern = "{\"body\": {\"n\": [2]}}" }, { pattern = "{\"body\": {\"n\": [3]}}" }, { pattern = "{\"body\": {\"n\": [4]}}" }, { pattern = "{\"body\": {\"n\": [5]}}" }, { pattern = "{\"body\": {\"n\": [6]}}" }] }
  }
  assert {
    condition     = length(aws_lambda_event_source_mapping.this.filter_criteria[0].filter) == 7
    error_message = "raised_filter_quota_7: exact resource/output wiring changed."
  }
}

run "raised_filter_quota_8" {
  command = plan
  variables {
    filter_criteria = { filter = [{ pattern = "{\"body\": {\"n\": [0]}}" }, { pattern = "{\"body\": {\"n\": [1]}}" }, { pattern = "{\"body\": {\"n\": [2]}}" }, { pattern = "{\"body\": {\"n\": [3]}}" }, { pattern = "{\"body\": {\"n\": [4]}}" }, { pattern = "{\"body\": {\"n\": [5]}}" }, { pattern = "{\"body\": {\"n\": [6]}}" }, { pattern = "{\"body\": {\"n\": [7]}}" }] }
  }
  assert {
    condition     = length(aws_lambda_event_source_mapping.this.filter_criteria[0].filter) == 8
    error_message = "raised_filter_quota_8: exact resource/output wiring changed."
  }
}

run "raised_filter_quota_9" {
  command = plan
  variables {
    filter_criteria = { filter = [{ pattern = "{\"body\": {\"n\": [0]}}" }, { pattern = "{\"body\": {\"n\": [1]}}" }, { pattern = "{\"body\": {\"n\": [2]}}" }, { pattern = "{\"body\": {\"n\": [3]}}" }, { pattern = "{\"body\": {\"n\": [4]}}" }, { pattern = "{\"body\": {\"n\": [5]}}" }, { pattern = "{\"body\": {\"n\": [6]}}" }, { pattern = "{\"body\": {\"n\": [7]}}" }, { pattern = "{\"body\": {\"n\": [8]}}" }] }
  }
  assert {
    condition     = length(aws_lambda_event_source_mapping.this.filter_criteria[0].filter) == 9
    error_message = "raised_filter_quota_9: exact resource/output wiring changed."
  }
}

run "raised_filter_quota_10" {
  command = plan
  variables {
    filter_criteria = { filter = [{ pattern = "{\"body\": {\"n\": [0]}}" }, { pattern = "{\"body\": {\"n\": [1]}}" }, { pattern = "{\"body\": {\"n\": [2]}}" }, { pattern = "{\"body\": {\"n\": [3]}}" }, { pattern = "{\"body\": {\"n\": [4]}}" }, { pattern = "{\"body\": {\"n\": [5]}}" }, { pattern = "{\"body\": {\"n\": [6]}}" }, { pattern = "{\"body\": {\"n\": [7]}}" }, { pattern = "{\"body\": {\"n\": [8]}}" }, { pattern = "{\"body\": {\"n\": [9]}}" }] }
  }
  assert {
    condition     = length(aws_lambda_event_source_mapping.this.filter_criteria[0].filter) == 10
    error_message = "raised_filter_quota_10: exact resource/output wiring changed."
  }
}

run "null_pattern" {
  command = plan
  variables {
    filter_criteria = { filter = [{}] }
  }
  assert {
    condition     = one(aws_lambda_event_source_mapping.this.filter_criteria[0].filter).pattern == null
    error_message = "null_pattern: exact resource/output wiring changed."
  }
}

run "stream_numeric_boundaries_0" {
  command = plan
  variables {
    event_source_arn              = "arn:aws:kinesis:us-east-1:123456789012:stream/events"
    starting_position             = "LATEST"
    maximum_record_age_in_seconds = -1
    maximum_retry_attempts        = -1
    parallelization_factor        = 1
    tumbling_window_in_seconds    = 0
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.maximum_record_age_in_seconds == -1
    error_message = "stream_numeric_boundaries_0: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.maximum_retry_attempts == -1
    error_message = "stream_numeric_boundaries_0: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.parallelization_factor == 1
    error_message = "stream_numeric_boundaries_0: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.tumbling_window_in_seconds == 0
    error_message = "stream_numeric_boundaries_0: exact resource/output wiring changed."
  }
}

run "stream_numeric_boundaries_1" {
  command = plan
  variables {
    event_source_arn              = "arn:aws:kinesis:us-east-1:123456789012:stream/events"
    starting_position             = "LATEST"
    maximum_record_age_in_seconds = 604800
    maximum_retry_attempts        = 10000
    parallelization_factor        = 10
    tumbling_window_in_seconds    = 900
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.maximum_record_age_in_seconds == 604800
    error_message = "stream_numeric_boundaries_1: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.maximum_retry_attempts == 10000
    error_message = "stream_numeric_boundaries_1: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.parallelization_factor == 10
    error_message = "stream_numeric_boundaries_1: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.tumbling_window_in_seconds == 900
    error_message = "stream_numeric_boundaries_1: exact resource/output wiring changed."
  }
}

run "batch_minimum" {
  command = plan
  variables {
    batch_size     = 1
    scaling_config = { maximum_concurrency = 2 }
  }
  assert {
    condition     = output.batch_size == 1
    error_message = "batch_minimum: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.scaling_config[0].maximum_concurrency == 2
    error_message = "batch_minimum: exact resource/output wiring changed."
  }
}

run "computed_output_contract" {
  command = apply
  assert {
    condition     = output.id == "00000000-0000-0000-0000-000000000537" && output.uuid == output.id
    error_message = "computed_output_contract: exact resource/output wiring changed."
  }
  assert {
    condition     = output.arn == "arn:aws:lambda:us-east-1:123456789012:event-source-mapping:00000000-0000-0000-0000-000000000537"
    error_message = "computed_output_contract: exact resource/output wiring changed."
  }
  assert {
    condition     = output.function_arn == "arn:aws:lambda:us-east-1:123456789012:function:worker"
    error_message = "computed_output_contract: exact resource/output wiring changed."
  }
  assert {
    condition     = output.state == "Enabled"
    error_message = "computed_output_contract: exact resource/output wiring changed."
  }
  assert {
    condition     = output.state_transition_reason == "USER_INITIATED"
    error_message = "computed_output_contract: exact resource/output wiring changed."
  }
  assert {
    condition     = output.last_modified == "2026-01-01T00:00:00Z"
    error_message = "computed_output_contract: exact resource/output wiring changed."
  }
  assert {
    condition     = output.last_processing_result == "OK"
    error_message = "computed_output_contract: exact resource/output wiring changed."
  }
  assert {
    condition     = output.tags_all == tomap({ Name = "worker" })
    error_message = "computed_output_contract: exact resource/output wiring changed."
  }
  assert {
    condition     = output.event_source_arn == "arn:aws:sqs:us-east-1:123456789012:work"
    error_message = "computed_output_contract: exact resource/output wiring changed."
  }
  assert {
    condition     = output.batch_size == 10 && output.enabled == true
    error_message = "computed_output_contract: exact resource/output wiring changed."
  }
  assert {
    condition     = output.function_response_types == setsubtract(toset(["ReportBatchItemFailures"]), toset(["ReportBatchItemFailures"]))
    error_message = "computed_output_contract: exact resource/output wiring changed."
  }
  assert {
    condition     = output.maximum_batching_window_in_seconds == null
    error_message = "computed_output_contract: exact resource/output wiring changed."
  }
}

run "mq_default_window" {
  command = plan
  variables {
    event_source_arn = "arn:aws:mq:us-east-1:123456789012:broker:events:b-00000000-0000-0000-0000-000000000000"
  }
  assert {
    condition     = output.maximum_batching_window_in_seconds == null
    error_message = "mq_default_window: exact resource/output wiring changed."
  }
}

run "documentdb_default_window" {
  command = plan
  variables {
    event_source_arn = "arn:aws:rds:us-east-1:123456789012:cluster:events"
  }
  assert {
    condition     = output.maximum_batching_window_in_seconds == null
    error_message = "documentdb_default_window: exact resource/output wiring changed."
  }
}

run "kafka_default_window" {
  command = plan
  variables {
    event_source_arn = "arn:aws:kafka:us-east-1:123456789012:cluster/events/00000000-0000-0000-0000-000000000000-1"
  }
  assert {
    condition     = output.maximum_batching_window_in_seconds == null
    error_message = "kafka_default_window: exact resource/output wiring changed."
  }
}

run "fifo_omitted_window" {
  command = plan
  variables {
    event_source_arn = "arn:aws:sqs:us-east-1:123456789012:work.fifo"
  }
  assert {
    condition     = output.maximum_batching_window_in_seconds == null
    error_message = "fifo_omitted_window: exact resource/output wiring changed."
  }
}

run "explicit_null_optional_controls" {
  command = plan
  variables {
    maximum_record_age_in_seconds            = null
    maximum_retry_attempts                   = null
    parallelization_factor                   = null
    tumbling_window_in_seconds               = null
    bisect_batch_on_function_error           = null
    destination_config                       = null
    filter_criteria                          = null
    kms_key_arn                              = null
    metrics_config                           = null
    scaling_config                           = null
    provisioned_poller_config                = null
    region                                   = null
    timeouts                                 = null
    amazon_managed_kafka_event_source_config = null
    self_managed_kafka_event_source_config   = null
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.timeouts == null && length(aws_lambda_event_source_mapping.this.metrics_config) == 0 && length(aws_lambda_event_source_mapping.this.scaling_config) == 0
    error_message = "explicit_null_optional_controls: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.tumbling_window_in_seconds == null && aws_lambda_event_source_mapping.this.bisect_batch_on_function_error == null && aws_lambda_event_source_mapping.this.kms_key_arn == null
    error_message = "explicit_null_optional_controls: exact resource/output wiring changed."
  }
  assert {
    condition     = length(aws_lambda_event_source_mapping.this.amazon_managed_kafka_event_source_config) == 0 && length(aws_lambda_event_source_mapping.this.self_managed_kafka_event_source_config) == 0
    error_message = "explicit_null_optional_controls: exact resource/output wiring changed."
  }
}

run "mq_queue_length_boundary" {
  command = plan
  variables {
    event_source_arn = "arn:aws:mq:us-east-1:123456789012:broker:events:b-00000000-0000-0000-0000-000000000000"
    queues           = ["qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq"]
  }
  assert {
    condition     = length(one(aws_lambda_event_source_mapping.this.queues)) == 1000
    error_message = "mq_queue_length_boundary: exact resource/output wiring changed."
  }
}

run "managed_registry_source_boundaries" {
  command = plan
  variables {
    event_source_arn                         = "arn:aws:kafka:us-east-1:123456789012:cluster/events/00000000-0000-0000-0000-000000000000-1"
    topics                                   = ["ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt"]
    amazon_managed_kafka_event_source_config = { consumer_group_id = "gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg", schema_registry_config = { event_record_format = "SOURCE", access_config = [{ type = "CLIENT_CERTIFICATE_TLS_AUTH", uri = "arn:aws:secretsmanager:us-east-1:123456789012:secret:fake-auth" }, { type = "SERVER_ROOT_CA_CERTIFICATE", uri = "arn:aws:secretsmanager:us-east-1:123456789012:secret:fake-auth" }], schema_validation_config = [{}] } }
    provisioned_poller_config                = { minimum_pollers = 200, maximum_pollers = 200, poller_group_name = "x" }
  }
  assert {
    condition     = length(one(aws_lambda_event_source_mapping.this.topics)) == 249 && length(aws_lambda_event_source_mapping.this.amazon_managed_kafka_event_source_config[0].consumer_group_id) == 200
    error_message = "managed_registry_source_boundaries: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.amazon_managed_kafka_event_source_config[0].schema_registry_config[0].event_record_format == "SOURCE"
    error_message = "managed_registry_source_boundaries: exact resource/output wiring changed."
  }
  assert {
    condition     = toset([for c in aws_lambda_event_source_mapping.this.amazon_managed_kafka_event_source_config[0].schema_registry_config[0].access_config : c.type]) == toset(["CLIENT_CERTIFICATE_TLS_AUTH", "SERVER_ROOT_CA_CERTIFICATE"])
    error_message = "managed_registry_source_boundaries: exact resource/output wiring changed."
  }
  assert {
    condition     = one(aws_lambda_event_source_mapping.this.amazon_managed_kafka_event_source_config[0].schema_registry_config[0].schema_validation_config).attribute == null
    error_message = "managed_registry_source_boundaries: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.provisioned_poller_config[0].minimum_pollers == 200 && aws_lambda_event_source_mapping.this.provisioned_poller_config[0].maximum_pollers == 200 && aws_lambda_event_source_mapping.this.provisioned_poller_config[0].poller_group_name == "x"
    error_message = "managed_registry_source_boundaries: exact resource/output wiring changed."
  }
}

run "self_registry_source_boundaries" {
  command = plan
  variables {
    event_source_arn                       = null
    topics                                 = ["ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt"]
    self_managed_kafka_event_source_config = { consumer_group_id = "gggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg", schema_registry_config = { event_record_format = "SOURCE", access_config = [{ type = "CLIENT_CERTIFICATE_TLS_AUTH", uri = "arn:aws:secretsmanager:us-east-1:123456789012:secret:fake-auth" }, { type = "SERVER_ROOT_CA_CERTIFICATE", uri = "arn:aws:secretsmanager:us-east-1:123456789012:secret:fake-auth" }], schema_validation_config = [{}] } }
    provisioned_poller_config              = { minimum_pollers = 200, maximum_pollers = 200, poller_group_name = "x" }
    self_managed_event_source              = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
  }
  assert {
    condition     = length(one(aws_lambda_event_source_mapping.this.topics)) == 249 && length(aws_lambda_event_source_mapping.this.self_managed_kafka_event_source_config[0].consumer_group_id) == 200
    error_message = "self_registry_source_boundaries: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.self_managed_kafka_event_source_config[0].schema_registry_config[0].event_record_format == "SOURCE"
    error_message = "self_registry_source_boundaries: exact resource/output wiring changed."
  }
  assert {
    condition     = toset([for c in aws_lambda_event_source_mapping.this.self_managed_kafka_event_source_config[0].schema_registry_config[0].access_config : c.type]) == toset(["CLIENT_CERTIFICATE_TLS_AUTH", "SERVER_ROOT_CA_CERTIFICATE"])
    error_message = "self_registry_source_boundaries: exact resource/output wiring changed."
  }
  assert {
    condition     = one(aws_lambda_event_source_mapping.this.self_managed_kafka_event_source_config[0].schema_registry_config[0].schema_validation_config).attribute == null
    error_message = "self_registry_source_boundaries: exact resource/output wiring changed."
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.provisioned_poller_config[0].minimum_pollers == 200 && aws_lambda_event_source_mapping.this.provisioned_poller_config[0].maximum_pollers == 200 && aws_lambda_event_source_mapping.this.provisioned_poller_config[0].poller_group_name == "x"
    error_message = "self_registry_source_boundaries: exact resource/output wiring changed."
  }
}

run "all_source_access_enums" {
  command = plan
  variables {
    event_source_arn            = null
    self_managed_event_source   = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
    source_access_configuration = [{ type = "BASIC_AUTH", uri = "fake" }, { type = "VPC_SUBNET", uri = "fake" }, { type = "VPC_SECURITY_GROUP", uri = "fake" }, { type = "SASL_SCRAM_512_AUTH", uri = "fake" }, { type = "SASL_SCRAM_256_AUTH", uri = "fake" }, { type = "VIRTUAL_HOST", uri = "fake" }, { type = "CLIENT_CERTIFICATE_TLS_AUTH", uri = "fake" }, { type = "SERVER_ROOT_CA_CERTIFICATE", uri = "fake" }]
  }
  assert {
    condition     = toset([for c in aws_lambda_event_source_mapping.this.source_access_configuration : c.type]) == toset(["BASIC_AUTH", "VPC_SUBNET", "VPC_SECURITY_GROUP", "SASL_SCRAM_512_AUTH", "SASL_SCRAM_256_AUTH", "VIRTUAL_HOST", "CLIENT_CERTIFICATE_TLS_AUTH", "SERVER_ROOT_CA_CERTIFICATE"])
    error_message = "all_source_access_enums: exact resource/output wiring changed."
  }
}

run "source_access_count_boundary" {
  command = plan
  variables {
    event_source_arn            = null
    self_managed_event_source   = { endpoints = { KAFKA_BOOTSTRAP_SERVERS = "broker.example.invalid:9092" } }
    source_access_configuration = [{ type = "VPC_SUBNET", uri = "subnet:subnet-00000000" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000001" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000002" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000003" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000004" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000005" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000006" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000007" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000008" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000009" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000010" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000011" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000012" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000013" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000014" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000015" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000016" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000017" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000018" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000019" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000020" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000021" }]
  }
  assert {
    condition     = length(aws_lambda_event_source_mapping.this.source_access_configuration) == 22
    error_message = "source_access_count_boundary: exact resource/output wiring changed."
  }
}

run "filter_pattern_length_boundary" {
  command = plan
  variables {
    filter_criteria = { filter = [{ pattern = "{\"x\":\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"}" }] }
  }
  assert {
    condition     = length(one(aws_lambda_event_source_mapping.this.filter_criteria[0].filter).pattern) == 4096
    error_message = "filter_pattern_length_boundary: exact resource/output wiring changed."
  }
}

run "documentdb_optional_fields_omitted" {
  command = plan
  variables {
    event_source_arn                = "arn:aws:rds:us-east-1:123456789012:cluster:events"
    document_db_event_source_config = { database_name = "app" }
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.document_db_event_source_config[0].full_document == "Default" && aws_lambda_event_source_mapping.this.document_db_event_source_config[0].collection_name == null
    error_message = "documentdb_optional_fields_omitted: exact resource/output wiring changed."
  }
}

run "documentdb_timestamp" {
  command = plan
  variables {
    event_source_arn            = "arn:aws:rds:us-east-1:123456789012:cluster:events"
    starting_position           = "AT_TIMESTAMP"
    starting_position_timestamp = "2026-01-01T00:00:00Z"
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.starting_position == "AT_TIMESTAMP" && aws_lambda_event_source_mapping.this.starting_position_timestamp == "2026-01-01T00:00:00Z"
    error_message = "documentdb_timestamp: exact resource/output wiring changed."
  }
}

run "poller_empty_object" {
  command = plan
  variables {
    event_source_arn          = "arn:aws:kafka:us-east-1:123456789012:cluster/events/00000000-0000-0000-0000-000000000000-1"
    provisioned_poller_config = {}
  }
  assert {
    condition     = length(aws_lambda_event_source_mapping.this.provisioned_poller_config) == 1
    error_message = "poller_empty_object: exact resource/output wiring changed."
  }
}

run "partial_timeouts" {
  command = plan
  variables {
    timeouts = { create = "20m" }
  }
  assert {
    condition     = aws_lambda_event_source_mapping.this.timeouts.create == "20m" && aws_lambda_event_source_mapping.this.timeouts.update == null && aws_lambda_event_source_mapping.this.timeouts.delete == null
    error_message = "partial_timeouts: exact resource/output wiring changed."
  }
}
