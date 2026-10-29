###########################
# Legacy compatible inputs
###########################
variable "function_name" {
  description = "Name or ARN of the subscribing Lambda function."
  type        = string
  nullable    = false
}

variable "event_source_arn" {
  description = "Kinesis, DynamoDB stream, SQS, MQ, MSK or DocumentDB ARN; omit for self-managed Kafka."
  type        = string
  default     = null
}

variable "batch_size" {
  description = "Maximum records per invocation. Legacy numeric string input; effective default remains 10 for every source."
  type        = string
  default     = "10"
  nullable    = false
  validation {
    condition     = try(tonumber(var.batch_size) == floor(tonumber(var.batch_size)) && tonumber(var.batch_size) >= 1 && tonumber(var.batch_size) <= 10000, false)
    error_message = "batch_size must be a numeric integer string from 1 through 10000."
  }
}

variable "enabled" {
  description = "Whether polling is enabled. Legacy boolean string input; accepts convertible booleans."
  type        = string
  default     = "true"
  nullable    = false
  validation {
    condition     = can(tobool(var.enabled))
    error_message = "enabled must be true or false."
  }
}

variable "starting_position" {
  description = "LATEST, TRIM_HORIZON or AT_TIMESTAMP; empty string omits the argument. Not supported by SQS or MQ."
  type        = string
  default     = ""
  nullable    = false
  validation {
    condition     = contains(["", "LATEST", "TRIM_HORIZON", "AT_TIMESTAMP"], var.starting_position)
    error_message = "starting_position must be empty, LATEST, TRIM_HORIZON or AT_TIMESTAMP."
  }
}

variable "starting_position_timestamp" {
  description = "RFC3339 starting timestamp for AT_TIMESTAMP; empty string omits the argument."
  type        = string
  default     = ""
  nullable    = false
  validation {
    condition     = var.starting_position_timestamp == "" ? true : can(formatdate("YYYY", var.starting_position_timestamp))
    error_message = "starting_position_timestamp must be empty or a valid RFC3339 timestamp."
  }
}

###########################
# Processing controls
###########################
variable "function_response_types" {
  description = "Empty or ReportBatchItemFailures; the function must implement partial failure responses. Kafka requires provisioned mode."
  type        = set(string)
  default     = []
  nullable    = false
  validation {
    condition     = alltrue([for response in var.function_response_types : response == "ReportBatchItemFailures"])
    error_message = "function_response_types accepts only ReportBatchItemFailures."
  }
}

variable "maximum_batching_window_in_seconds" {
  description = "Integer batching window 0..300; null preserves source defaults (including 500ms)."
  type        = number
  default     = null
  validation {
    condition     = var.maximum_batching_window_in_seconds == null ? true : var.maximum_batching_window_in_seconds == floor(var.maximum_batching_window_in_seconds) && var.maximum_batching_window_in_seconds >= 0 && var.maximum_batching_window_in_seconds <= 300
    error_message = "maximum_batching_window_in_seconds must be an integer from 0 through 300."
  }
}

variable "maximum_record_age_in_seconds" {
  description = "Discard old stream/Kafka records: -1 for infinite, or integer 60..604800 seconds. Explicit Kafka configuration requires provisioned mode."
  type        = number
  default     = null
  validation {
    condition     = var.maximum_record_age_in_seconds == null ? true : var.maximum_record_age_in_seconds == floor(var.maximum_record_age_in_seconds) && (var.maximum_record_age_in_seconds == -1 || (var.maximum_record_age_in_seconds >= 60 && var.maximum_record_age_in_seconds <= 604800))
    error_message = "maximum_record_age_in_seconds must be -1 or an integer from 60 through 604800."
  }
}

variable "maximum_retry_attempts" {
  description = "Stream/Kafka retry limit: integer -1 (infinite) through 10000. Explicit Kafka configuration requires provisioned mode."
  type        = number
  default     = null
  validation {
    condition     = var.maximum_retry_attempts == null ? true : var.maximum_retry_attempts == floor(var.maximum_retry_attempts) && var.maximum_retry_attempts >= -1 && var.maximum_retry_attempts <= 10000
    error_message = "maximum_retry_attempts must be an integer from -1 through 10000."
  }
}

variable "parallelization_factor" {
  description = "Concurrent batches per Kinesis/DynamoDB shard, integer 1..10."
  type        = number
  default     = null
  validation {
    condition     = var.parallelization_factor == null ? true : var.parallelization_factor == floor(var.parallelization_factor) && var.parallelization_factor >= 1 && var.parallelization_factor <= 10
    error_message = "parallelization_factor must be an integer from 1 through 10."
  }
}

variable "tumbling_window_in_seconds" {
  description = "Kinesis/DynamoDB aggregation window, integer 0..900."
  type        = number
  default     = null
  validation {
    condition     = var.tumbling_window_in_seconds == null ? true : var.tumbling_window_in_seconds == floor(var.tumbling_window_in_seconds) && var.tumbling_window_in_seconds >= 0 && var.tumbling_window_in_seconds <= 900
    error_message = "tumbling_window_in_seconds must be an integer from 0 through 900."
  }
}

variable "bisect_batch_on_function_error" {
  description = "Split failed batches for stream/Kafka sources. Enabling this for Kafka requires provisioned mode."
  type        = bool
  default     = null
}

variable "destination_config" {
  description = "Destination for discarded stream/Kafka records, including Kafka on-demand mode. Caller provisions destination and permissions."
  type = object({
    on_failure = optional(object({ destination_arn = string }))
  })
  default = null
}

variable "filter_criteria" {
  description = "Up to ten JSON event filters (six through ten require an increased service quota)."
  type = object({
    filter = optional(set(object({ pattern = optional(string) })), [])
  })
  default = null
  validation {
    condition     = var.filter_criteria == null ? true : length(var.filter_criteria.filter) <= 10
    error_message = "filter_criteria permits at most ten filters."
  }
  validation {
    condition     = var.filter_criteria == null ? true : alltrue([for f in var.filter_criteria.filter : f.pattern == null ? true : can(jsondecode(f.pattern))])
    error_message = "Each non-null filter pattern must be valid JSON."
  }
  validation {
    condition     = var.filter_criteria == null ? true : alltrue([for f in var.filter_criteria.filter : f.pattern == null ? true : length(f.pattern) <= 4096])
    error_message = "Each filter pattern must be at most 4096 characters."
  }
}

variable "kms_key_arn" {
  description = "Existing customer managed key ARN for encrypting filter criteria. No key is created."
  type        = string
  default     = null
}

variable "metrics_config" {
  description = "Enhanced event source metrics: EventCount, ErrorCount and/or KafkaMetrics. ErrorCount and KafkaMetrics require Amazon MSK or self-managed Kafka."
  type        = object({ metrics = set(string) })
  default     = null
  validation {
    condition     = var.metrics_config == null ? true : length(var.metrics_config.metrics) > 0 && alltrue([for m in var.metrics_config.metrics : contains(["EventCount", "ErrorCount", "KafkaMetrics"], m)])
    error_message = "metrics_config.metrics must be nonempty and contain only EventCount, ErrorCount or KafkaMetrics."
  }
}

variable "scaling_config" {
  description = "SQS maximum concurrency, integer >=2. An empty object clears the setting."
  type        = object({ maximum_concurrency = optional(number) })
  default     = null
  validation {
    condition     = try(var.scaling_config.maximum_concurrency, null) == null ? true : var.scaling_config.maximum_concurrency == floor(var.scaling_config.maximum_concurrency) && var.scaling_config.maximum_concurrency >= 2
    error_message = "scaling_config.maximum_concurrency must be an integer of at least 2."
  }
}

variable "provisioned_poller_config" {
  description = "Dedicated Kafka/SQS pollers: minimum 1..200 (SQS 2..200), maximum 1..2000. Optional poller_group_name is Kafka-only."
  type = object({
    minimum_pollers   = optional(number)
    maximum_pollers   = optional(number)
    poller_group_name = optional(string)
  })
  default = null
  validation {
    condition     = try(var.provisioned_poller_config.minimum_pollers, null) == null ? true : var.provisioned_poller_config.minimum_pollers == floor(var.provisioned_poller_config.minimum_pollers) && var.provisioned_poller_config.minimum_pollers >= 1 && var.provisioned_poller_config.minimum_pollers <= 200
    error_message = "minimum_pollers must be an integer from 1 through 200."
  }
  validation {
    condition     = try(var.provisioned_poller_config.maximum_pollers, null) == null ? true : var.provisioned_poller_config.maximum_pollers == floor(var.provisioned_poller_config.maximum_pollers) && var.provisioned_poller_config.maximum_pollers >= 1 && var.provisioned_poller_config.maximum_pollers <= 2000
    error_message = "maximum_pollers must be an integer from 1 through 2000."
  }
  validation {
    condition     = try(var.provisioned_poller_config.minimum_pollers, null) == null || try(var.provisioned_poller_config.maximum_pollers, null) == null ? true : var.provisioned_poller_config.minimum_pollers <= var.provisioned_poller_config.maximum_pollers
    error_message = "minimum_pollers must not exceed maximum_pollers."
  }
  validation {
    condition     = try(var.provisioned_poller_config.poller_group_name, null) == null ? true : length(var.provisioned_poller_config.poller_group_name) >= 1 && length(var.provisioned_poller_config.poller_group_name) <= 128
    error_message = "poller_group_name length must be from 1 through 128."
  }
}

###########################
# Source-specific settings
###########################
variable "document_db_event_source_config" {
  description = "DocumentDB database, optional collection and full-document mode."
  type = object({
    database_name   = string
    collection_name = optional(string)
    full_document   = optional(string, "Default")
  })
  default = null
  validation {
    condition     = var.document_db_event_source_config == null ? true : contains(["Default", "UpdateLookup"], var.document_db_event_source_config.full_document)
    error_message = "DocumentDB full_document must be Default or UpdateLookup."
  }
}

variable "queues" {
  description = "Exactly one destination queue name of 1..1000 characters is required for MQ; empty for other sources."
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = length(var.queues) <= 1 && alltrue([for q in var.queues : q == null ? false : length(q) >= 1 && length(q) <= 1000])
    error_message = "queues must be empty or contain one queue name of 1..1000 characters."
  }
}

variable "topics" {
  description = "Exactly one topic of 1..249 characters is required for Kafka; empty for other sources."
  type        = set(string)
  default     = []
  nullable    = false
  validation {
    condition     = length(var.topics) <= 1 && alltrue([for t in var.topics : t == null ? false : length(t) >= 1 && length(t) <= 249])
    error_message = "topics must be empty or contain one topic name of 1..249 characters."
  }
}

variable "self_managed_event_source" {
  description = "Self-managed Kafka bootstrap endpoints (KAFKA_BOOTSTRAP_SERVERS => comma-separated brokers). Conflicts with an ARN source."
  type        = object({ endpoints = map(string) })
  default     = null
}

variable "source_access_configuration" {
  description = "Source authentication and network access configuration; existing secrets/network resources only."
  type        = set(object({ type = string, uri = string }))
  default     = []
  nullable    = false
  validation {
    condition     = length(var.source_access_configuration) <= 22
    error_message = "At most 22 source_access_configuration entries are permitted."
  }
  validation {
    condition     = alltrue([for c in var.source_access_configuration : contains(["BASIC_AUTH", "VPC_SUBNET", "VPC_SECURITY_GROUP", "SASL_SCRAM_512_AUTH", "SASL_SCRAM_256_AUTH", "VIRTUAL_HOST", "CLIENT_CERTIFICATE_TLS_AUTH", "SERVER_ROOT_CA_CERTIFICATE"], c.type)])
    error_message = "source_access_configuration type must be a supported authentication, VPC or virtual-host type."
  }
}

variable "amazon_managed_kafka_event_source_config" {
  description = "MSK consumer group and optional schema registry settings. Configured schema registries require provisioned mode."
  type = object({
    consumer_group_id = optional(string)
    schema_registry_config = optional(object({
      access_config            = optional(set(object({ type = optional(string), uri = optional(string) })), [])
      event_record_format      = optional(string)
      schema_registry_uri      = optional(string)
      schema_validation_config = optional(set(object({ attribute = optional(string) })), [])
    }))
  })
  default = null
  validation {
    condition     = try(var.amazon_managed_kafka_event_source_config.consumer_group_id, null) == null ? true : length(var.amazon_managed_kafka_event_source_config.consumer_group_id) >= 1 && length(var.amazon_managed_kafka_event_source_config.consumer_group_id) <= 200
    error_message = "MSK consumer_group_id length must be from 1 through 200."
  }
  validation {
    condition     = try(var.amazon_managed_kafka_event_source_config.schema_registry_config.event_record_format, null) == null ? true : contains(["JSON", "SOURCE"], var.amazon_managed_kafka_event_source_config.schema_registry_config.event_record_format)
    error_message = "MSK registry event_record_format must be JSON or SOURCE."
  }
  validation {
    condition     = alltrue([for c in try(var.amazon_managed_kafka_event_source_config.schema_registry_config.access_config, []) : c.type == null ? true : contains(["BASIC_AUTH", "CLIENT_CERTIFICATE_TLS_AUTH", "SERVER_ROOT_CA_CERTIFICATE"], c.type)])
    error_message = "MSK registry access type must be BASIC_AUTH, CLIENT_CERTIFICATE_TLS_AUTH or SERVER_ROOT_CA_CERTIFICATE."
  }
  validation {
    condition     = alltrue([for c in try(var.amazon_managed_kafka_event_source_config.schema_registry_config.schema_validation_config, []) : c.attribute == null ? true : contains(["KEY", "VALUE"], c.attribute)])
    error_message = "MSK schema validation attribute must be KEY or VALUE."
  }
}

variable "self_managed_kafka_event_source_config" {
  description = "Self-managed Kafka consumer group and optional schema registry settings. Configured schema registries require provisioned mode."
  type = object({
    consumer_group_id = optional(string)
    schema_registry_config = optional(object({
      access_config            = optional(set(object({ type = optional(string), uri = optional(string) })), [])
      event_record_format      = optional(string)
      schema_registry_uri      = optional(string)
      schema_validation_config = optional(set(object({ attribute = optional(string) })), [])
    }))
  })
  default = null
  validation {
    condition     = try(var.self_managed_kafka_event_source_config.consumer_group_id, null) == null ? true : length(var.self_managed_kafka_event_source_config.consumer_group_id) >= 1 && length(var.self_managed_kafka_event_source_config.consumer_group_id) <= 200
    error_message = "Kafka consumer_group_id length must be from 1 through 200."
  }
  validation {
    condition     = try(var.self_managed_kafka_event_source_config.schema_registry_config.event_record_format, null) == null ? true : contains(["JSON", "SOURCE"], var.self_managed_kafka_event_source_config.schema_registry_config.event_record_format)
    error_message = "Kafka registry event_record_format must be JSON or SOURCE."
  }
  validation {
    condition     = alltrue([for c in try(var.self_managed_kafka_event_source_config.schema_registry_config.access_config, []) : c.type == null ? true : contains(["BASIC_AUTH", "CLIENT_CERTIFICATE_TLS_AUTH", "SERVER_ROOT_CA_CERTIFICATE"], c.type)])
    error_message = "Kafka registry access type must be BASIC_AUTH, CLIENT_CERTIFICATE_TLS_AUTH or SERVER_ROOT_CA_CERTIFICATE."
  }
  validation {
    condition     = alltrue([for c in try(var.self_managed_kafka_event_source_config.schema_registry_config.schema_validation_config, []) : c.attribute == null ? true : contains(["KEY", "VALUE"], c.attribute)])
    error_message = "Kafka schema validation attribute must be KEY or VALUE."
  }
}

###########################
# Resource management
###########################
variable "region" {
  description = "Resource region override; null inherits the provider region."
  type        = string
  default     = null
}

variable "tags" {
  description = "Mapping tags merged over Name=function_name; caller Name wins."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "use_resource_timeout_for_propagation" {
  description = "Use operation timeouts for mapping propagation instead of the provider propagation timeout."
  type        = bool
  default     = false
  nullable    = false
}

variable "timeouts" {
  description = "Optional create, update and delete operation timeout overrides."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
