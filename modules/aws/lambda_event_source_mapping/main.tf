terraform {
  # Optional object defaults require Terraform 1.3 (also supported by OpenTofu).
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # 6.54.0 introduced timeouts and use_resource_timeout_for_propagation.
      version = ">= 6.54.0"
    }
  }
}

###########################
# Source classification
###########################
locals {
  service     = try(split(":", var.event_source_arn)[2], "")
  sqs         = local.service == "sqs"
  fifo        = local.sqs && try(endswith(var.event_source_arn, ".fifo"), false)
  stream      = contains(["kinesis", "dynamodb"], local.service)
  kafka       = local.service == "kafka" || var.self_managed_event_source != null
  document_db = local.service == "rds"
  mq          = local.service == "mq"
  position    = var.starting_position == "" ? null : var.starting_position
  timestamp   = var.starting_position_timestamp == "" ? null : var.starting_position_timestamp
}

###########################
# Singleton mapping
###########################
resource "aws_lambda_event_source_mapping" "this" {
  region                               = var.region
  function_name                        = var.function_name
  event_source_arn                     = var.event_source_arn
  batch_size                           = try(tonumber(var.batch_size), null)
  enabled                              = try(tobool(var.enabled), null)
  function_response_types              = var.function_response_types
  maximum_batching_window_in_seconds   = var.maximum_batching_window_in_seconds
  starting_position                    = local.sqs ? null : local.position
  starting_position_timestamp          = local.sqs ? null : local.timestamp
  bisect_batch_on_function_error       = var.bisect_batch_on_function_error
  kms_key_arn                          = var.kms_key_arn
  maximum_record_age_in_seconds        = var.maximum_record_age_in_seconds
  maximum_retry_attempts               = var.maximum_retry_attempts
  parallelization_factor               = var.parallelization_factor
  tumbling_window_in_seconds           = var.tumbling_window_in_seconds
  queues                               = var.queues
  topics                               = var.topics
  use_resource_timeout_for_propagation = var.use_resource_timeout_for_propagation
  tags                                 = merge({ Name = var.function_name }, var.tags)

  dynamic "destination_config" {
    for_each = var.destination_config == null ? [] : [var.destination_config]
    content {
      dynamic "on_failure" {
        for_each = destination_config.value.on_failure == null ? [] : [destination_config.value.on_failure]
        content {
          destination_arn = on_failure.value.destination_arn
        }
      }
    }
  }

  dynamic "document_db_event_source_config" {
    for_each = var.document_db_event_source_config == null ? [] : [var.document_db_event_source_config]
    content {
      database_name   = document_db_event_source_config.value.database_name
      collection_name = document_db_event_source_config.value.collection_name
      full_document   = document_db_event_source_config.value.full_document
    }
  }

  dynamic "filter_criteria" {
    for_each = var.filter_criteria == null ? [] : [var.filter_criteria]
    content {
      dynamic "filter" {
        for_each = filter_criteria.value.filter
        content {
          pattern = filter.value.pattern
        }
      }
    }
  }

  dynamic "metrics_config" {
    for_each = var.metrics_config == null ? [] : [var.metrics_config]
    content {
      metrics = metrics_config.value.metrics
    }
  }

  dynamic "provisioned_poller_config" {
    for_each = var.provisioned_poller_config == null ? [] : [var.provisioned_poller_config]
    content {
      minimum_pollers   = provisioned_poller_config.value.minimum_pollers
      maximum_pollers   = provisioned_poller_config.value.maximum_pollers
      poller_group_name = provisioned_poller_config.value.poller_group_name
    }
  }

  dynamic "scaling_config" {
    for_each = var.scaling_config == null ? [] : [var.scaling_config]
    content {
      maximum_concurrency = scaling_config.value.maximum_concurrency
    }
  }

  dynamic "self_managed_event_source" {
    for_each = var.self_managed_event_source == null ? [] : [var.self_managed_event_source]
    content {
      endpoints = self_managed_event_source.value.endpoints
    }
  }

  dynamic "source_access_configuration" {
    for_each = var.source_access_configuration
    content {
      type = source_access_configuration.value.type
      uri  = source_access_configuration.value.uri
    }
  }

  dynamic "amazon_managed_kafka_event_source_config" {
    for_each = var.amazon_managed_kafka_event_source_config == null ? [] : [var.amazon_managed_kafka_event_source_config]
    content {
      consumer_group_id = amazon_managed_kafka_event_source_config.value.consumer_group_id
      dynamic "schema_registry_config" {
        for_each = amazon_managed_kafka_event_source_config.value.schema_registry_config == null ? [] : [amazon_managed_kafka_event_source_config.value.schema_registry_config]
        content {
          event_record_format = schema_registry_config.value.event_record_format
          schema_registry_uri = schema_registry_config.value.schema_registry_uri
          dynamic "access_config" {
            for_each = schema_registry_config.value.access_config
            content {
              type = access_config.value.type
              uri  = access_config.value.uri
            }
          }
          dynamic "schema_validation_config" {
            for_each = schema_registry_config.value.schema_validation_config
            content {
              attribute = schema_validation_config.value.attribute
            }
          }
        }
      }
    }
  }

  dynamic "self_managed_kafka_event_source_config" {
    for_each = var.self_managed_kafka_event_source_config == null ? [] : [var.self_managed_kafka_event_source_config]
    content {
      consumer_group_id = self_managed_kafka_event_source_config.value.consumer_group_id
      dynamic "schema_registry_config" {
        for_each = self_managed_kafka_event_source_config.value.schema_registry_config == null ? [] : [self_managed_kafka_event_source_config.value.schema_registry_config]
        content {
          event_record_format = schema_registry_config.value.event_record_format
          schema_registry_uri = schema_registry_config.value.schema_registry_uri
          dynamic "access_config" {
            for_each = schema_registry_config.value.access_config
            content {
              type = access_config.value.type
              uri  = access_config.value.uri
            }
          }
          dynamic "schema_validation_config" {
            for_each = schema_registry_config.value.schema_validation_config
            content {
              attribute = schema_validation_config.value.attribute
            }
          }
        }
      }
    }
  }

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    precondition {
      condition     = (var.event_source_arn != null) != (var.self_managed_event_source != null)
      error_message = "Supply exactly one event_source_arn or self_managed_event_source."
    }
    precondition {
      condition     = !local.fifo || try(tonumber(var.batch_size) <= 10, true)
      error_message = "FIFO SQS batch_size must not exceed 10."
    }
    precondition {
      condition     = !local.sqs || local.fifo || try(tonumber(var.batch_size) <= 10, true) || try(var.maximum_batching_window_in_seconds >= 1, false)
      error_message = "Standard SQS batch_size above 10 requires a batching window of at least 1 second."
    }
    precondition {
      condition     = !local.fifo || var.maximum_batching_window_in_seconds == null ? true : var.maximum_batching_window_in_seconds == 0
      error_message = "FIFO SQS does not support a positive batching window."
    }
    precondition {
      condition     = length(var.function_response_types) == 0 || local.sqs || local.stream || local.kafka
      error_message = "Partial batch responses require SQS, Kinesis, DynamoDB or Kafka."
    }
    precondition {
      condition     = var.metrics_config == null ? true : (local.kafka || length(setintersection(var.metrics_config.metrics, toset(["ErrorCount", "KafkaMetrics"]))) == 0)
      error_message = "ErrorCount and KafkaMetrics require an Amazon MSK or self-managed Kafka source; use EventCount for other supported sources."
    }
    precondition {
      condition     = (!local.sqs && !local.mq) || (local.position == null && local.timestamp == null)
      error_message = "SQS and MQ do not accept stream starting-position arguments."
    }
    precondition {
      condition     = !local.stream || local.position != null
      error_message = "Kinesis and DynamoDB streams require starting_position."
    }
    precondition {
      condition     = local.timestamp == null || local.position == "AT_TIMESTAMP"
      error_message = "A starting timestamp requires starting_position=AT_TIMESTAMP."
    }
    precondition {
      condition     = local.position != "AT_TIMESTAMP" || local.timestamp != null
      error_message = "AT_TIMESTAMP requires starting_position_timestamp."
    }
    precondition {
      condition     = local.position != "AT_TIMESTAMP" || local.service == "kinesis" || local.kafka || local.document_db
      error_message = "AT_TIMESTAMP is supported only by Kinesis, Kafka and DocumentDB, not DynamoDB."
    }
    precondition {
      condition     = var.amazon_managed_kafka_event_source_config == null || (local.service == "kafka" && var.self_managed_event_source == null && var.self_managed_kafka_event_source_config == null)
      error_message = "Managed Kafka settings require an MSK ARN and conflict with self-managed Kafka."
    }
    precondition {
      condition     = var.self_managed_kafka_event_source_config == null || (var.self_managed_event_source != null && var.event_source_arn == null && var.amazon_managed_kafka_event_source_config == null)
      error_message = "Self-managed Kafka settings require self_managed_event_source and conflict with ARN/managed settings."
    }
    precondition {
      condition     = length(var.topics) == 0 || local.kafka
      error_message = "topics is supported only by Kafka sources."
    }
    precondition {
      condition     = length(var.queues) == 0 || local.mq
      error_message = "queues is supported only by MQ sources."
    }
    precondition {
      condition     = var.scaling_config == null || local.sqs
      error_message = "scaling_config is supported only by SQS."
    }
    precondition {
      condition     = var.document_db_event_source_config == null || local.document_db
      error_message = "document_db_event_source_config requires a DocumentDB (rds) ARN."
    }
    precondition {
      condition     = var.provisioned_poller_config == null || local.kafka || local.sqs
      error_message = "Provisioned pollers require Kafka or SQS."
    }
    precondition {
      condition     = try(var.provisioned_poller_config.poller_group_name, null) == null || local.kafka
      error_message = "poller_group_name requires an Amazon MSK or self-managed Kafka source; omit the group name for SQS."
    }
    precondition {
      condition     = !local.sqs || try(var.provisioned_poller_config.minimum_pollers, null) == null ? true : var.provisioned_poller_config.minimum_pollers >= 2
      error_message = "SQS minimum_pollers must be at least 2."
    }
    precondition {
      condition     = !local.sqs || try(var.provisioned_poller_config.maximum_pollers, null) == null ? true : var.provisioned_poller_config.maximum_pollers >= 2
      error_message = "SQS maximum_pollers must be at least 2."
    }
    precondition {
      condition     = !local.sqs || var.provisioned_poller_config == null || try(var.scaling_config.maximum_concurrency, null) == null
      error_message = "SQS provisioned mode conflicts with maximum concurrency scaling."
    }
    precondition {
      condition     = (var.bisect_batch_on_function_error == null && var.maximum_record_age_in_seconds == null && var.maximum_retry_attempts == null && var.destination_config == null) || local.stream || local.kafka
      error_message = "Retry, record age, bisect and failure destinations require stream or Kafka sources."
    }
    precondition {
      condition     = (var.parallelization_factor == null && var.tumbling_window_in_seconds == null) || local.stream
      error_message = "Parallelization and tumbling windows require Kinesis or DynamoDB."
    }
  }
}
