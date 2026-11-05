###########################
# KMS Variables
###########################

variable "create_kms_key" {
  description = "Create the legacy customer-managed key and alias through the KMS child module."
  type        = bool
  default     = true
  nullable    = false
}

variable "key_customer_master_key_spec" {
  description = "Legacy KMS key specification. SQS-created keys must use SYMMETRIC_DEFAULT."
  type        = string
  default     = "SYMMETRIC_DEFAULT"
  nullable    = false
  validation {
    condition     = contains(["SYMMETRIC_DEFAULT", "RSA_2048", "RSA_3072", "RSA_4096", "ECC_NIST_P256", "ECC_NIST_P384", "ECC_NIST_P521", "ECC_SECG_P256K1"], var.key_customer_master_key_spec)
    error_message = "Choose a supported legacy KMS key spec (SYMMETRIC_DEFAULT, RSA_2048/3072/4096, ECC_NIST_P256/384/521 or ECC_SECG_P256K1)."
  }
}

variable "key_description" {
  description = "Description passed unchanged to the created key; the historical audit-log description is retained for compatibility."
  type        = string
  default     = "CloudTrail kms key used to encrypt audit logs"
}

variable "key_deletion_window_in_days" {
  description = "Created key deletion waiting period, integer days from 7 through 30."
  type        = number
  default     = 30
  nullable    = false
  validation {
    condition     = var.key_deletion_window_in_days >= 7 && var.key_deletion_window_in_days <= 30 && floor(var.key_deletion_window_in_days) == var.key_deletion_window_in_days
    error_message = "Set key_deletion_window_in_days to an integer from 7 through 30."
  }
}

variable "key_enable_key_rotation" {
  description = "Enable automatic rotation on the created key (legacy default true)."
  type        = bool
  default     = true
  nullable    = false
}

variable "key_usage" {
  description = "Created key usage; SQS requires ENCRYPT_DECRYPT."
  type        = string
  default     = "ENCRYPT_DECRYPT"
  nullable    = false
}

variable "key_is_enabled" {
  description = "Whether the created key is enabled."
  type        = bool
  default     = true
  nullable    = false
}

variable "key_name_prefix" {
  description = "Created alias prefix, including the required alias/ prefix."
  type        = string
  default     = "alias/sqs_key_"
  nullable    = false
  validation {
    condition     = startswith(var.key_name_prefix, "alias/")
    error_message = "Start key_name_prefix with alias/."
  }
}

variable "key_policy" {
  description = "Explicit created-key JSON policy; null generates an account-delegated, queue-scoped service-use policy."
  type        = string
  default     = null
  validation {
    condition     = var.key_policy == null ? true : can(jsondecode(var.key_policy))
    error_message = "Provide valid JSON for key_policy, or null for the generated policy."
  }
}

variable "kms_master_key_id" {
  description = "External KMS key ARN, key ID or alias; requires create_kms_key = false."
  type        = string
  default     = null
}

variable "sqs_managed_sse_enabled" {
  description = "SQS-owned encryption selection; omit for KMS. With no KMS, null delegates to the provider and false explicitly disables encryption."
  type        = bool
  default     = null
}

variable "kms_data_key_reuse_period_seconds" {
  description = "KMS data-key reuse interval, integer seconds from 60 through 86400; omitted in non-KMS modes."
  type        = number
  default     = 300
  nullable    = false
  validation {
    condition     = var.kms_data_key_reuse_period_seconds >= 60 && var.kms_data_key_reuse_period_seconds <= 86400 && floor(var.kms_data_key_reuse_period_seconds) == var.kms_data_key_reuse_period_seconds
    error_message = "Set kms_data_key_reuse_period_seconds to an integer from 60 through 86400."
  }
}

###########################
# SQS Queue Variables
###########################

variable "name" {
  description = "Physical queue name; explicitly set null for provider-generated naming."
  type        = string
}

variable "name_prefix" {
  description = "Generated queue-name prefix, mutually exclusive with a non-null name."
  type        = string
  default     = null
}

variable "fifo_queue" {
  description = "Whether to create a FIFO queue; changing queue type replaces the queue."
  type        = bool
  default     = false
  nullable    = false
}

variable "content_based_deduplication" {
  description = "Content-based deduplication for FIFO queues."
  type        = bool
  default     = false
}

variable "deduplication_scope" {
  description = "FIFO deduplication scope: queue or messageGroup."
  type        = string
  default     = null
  validation {
    condition     = var.deduplication_scope == null ? true : contains(["queue", "messageGroup"], var.deduplication_scope)
    error_message = "Set deduplication_scope to queue or messageGroup, or null."
  }
}

variable "fifo_throughput_limit" {
  description = "FIFO throughput limit: perQueue or perMessageGroupId."
  type        = string
  default     = null
  validation {
    condition     = var.fifo_throughput_limit == null ? true : contains(["perQueue", "perMessageGroupId"], var.fifo_throughput_limit)
    error_message = "Set fifo_throughput_limit to perQueue or perMessageGroupId, or null."
  }
}

variable "delay_seconds" {
  description = "Message delivery delay, integer seconds from 0 through 900."
  type        = number
  default     = 0
  nullable    = false
  validation {
    condition     = var.delay_seconds >= 0 && var.delay_seconds <= 900 && floor(var.delay_seconds) == var.delay_seconds
    error_message = "Set delay_seconds to an integer from 0 through 900."
  }
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout, integer seconds from 0 through 43200. Numeric strings remain convertible."
  type        = number
  default     = 30
  nullable    = false
  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200 && floor(var.visibility_timeout_seconds) == var.visibility_timeout_seconds
    error_message = "Set visibility_timeout_seconds to an integer from 0 through 43200."
  }
}

variable "message_retention_seconds" {
  description = "Message retention, integer seconds from 60 through 1209600."
  type        = number
  default     = 345600
  nullable    = false
  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600 && floor(var.message_retention_seconds) == var.message_retention_seconds
    error_message = "Set message_retention_seconds to an integer from 60 through 1209600."
  }
}

variable "max_message_size" {
  description = "Maximum message size, integer bytes from 1024 through 1048576; null uses the provider default."
  type        = number
  default     = 262144
  validation {
    condition     = var.max_message_size == null ? true : (var.max_message_size >= 1024 && var.max_message_size <= 1048576 && floor(var.max_message_size) == var.max_message_size)
    error_message = "Set max_message_size to an integer from 1024 through 1048576, or null."
  }
}

variable "receive_wait_time_seconds" {
  description = "Long-poll wait, integer seconds from 0 through 20; null uses the provider default."
  type        = number
  default     = 0
  validation {
    condition     = var.receive_wait_time_seconds == null ? true : (var.receive_wait_time_seconds >= 0 && var.receive_wait_time_seconds <= 20 && floor(var.receive_wait_time_seconds) == var.receive_wait_time_seconds)
    error_message = "Set receive_wait_time_seconds to an integer from 0 through 20, or null."
  }
}

variable "policy" {
  description = "Queue access-policy JSON with explicit Version = 2012-10-17; managed inline only."
  type        = string
  default     = null
  validation {
    condition     = var.policy == null ? true : can(jsondecode(var.policy))
    error_message = "Provide valid JSON for policy, or null."
  }
  validation {
    condition     = var.policy == null ? true : try(jsondecode(var.policy).Version == "2012-10-17", false)
    error_message = "Include Version = 2012-10-17 in the queue policy."
  }
}

variable "redrive_policy" {
  description = "Inline dead-letter JSON with nonempty deadLetterTargetArn and numeric integer maxReceiveCount from 1 through 1000."
  type        = string
  default     = null
  validation {
    condition     = var.redrive_policy == null ? true : can(jsondecode(var.redrive_policy))
    error_message = "Provide valid JSON for redrive_policy, or null."
  }
  validation {
    condition     = var.redrive_policy == null ? true : can(regex("^arn:[^:]+:sqs:[^:]+:[0-9]{12}:.+$", jsondecode(var.redrive_policy).deadLetterTargetArn))
    error_message = "Include a nonempty SQS deadLetterTargetArn in redrive_policy."
  }
  validation {
    condition = var.redrive_policy == null ? true : try(
      jsonencode(jsondecode(var.redrive_policy).maxReceiveCount) == tostring(jsondecode(var.redrive_policy).maxReceiveCount) &&
      floor(jsondecode(var.redrive_policy).maxReceiveCount) == jsondecode(var.redrive_policy).maxReceiveCount &&
      jsondecode(var.redrive_policy).maxReceiveCount >= 1 && jsondecode(var.redrive_policy).maxReceiveCount <= 1000, false
    )
    error_message = "Include maxReceiveCount as a JSON number (not a string), integer 1 through 1000."
  }
}

variable "redrive_allow_policy" {
  description = "Inline DLQ permission JSON: allowAll, denyAll, or byQueue with 1 through 10 sourceQueueArns."
  type        = string
  default     = null
  validation {
    condition     = var.redrive_allow_policy == null ? true : can(jsondecode(var.redrive_allow_policy))
    error_message = "Provide valid JSON for redrive_allow_policy, or null."
  }
  validation {
    condition     = var.redrive_allow_policy == null ? true : try(contains(["allowAll", "denyAll", "byQueue"], jsondecode(var.redrive_allow_policy).redrivePermission), false)
    error_message = "Set redrivePermission to allowAll, denyAll or byQueue."
  }
  validation {
    condition = var.redrive_allow_policy == null ? true : try(
      jsondecode(var.redrive_allow_policy).redrivePermission == "byQueue" ? (
        can(tolist(jsondecode(var.redrive_allow_policy).sourceQueueArns)) &&
        length(jsondecode(var.redrive_allow_policy).sourceQueueArns) >= 1 &&
        length(jsondecode(var.redrive_allow_policy).sourceQueueArns) <= 10 &&
        alltrue([for arn in jsondecode(var.redrive_allow_policy).sourceQueueArns : can(regex("^arn:[^:]+:sqs:[^:]+:[0-9]{12}:.+$", arn))])
      ) : !contains(keys(jsondecode(var.redrive_allow_policy)), "sourceQueueArns"), false
    )
    error_message = "byQueue requires an array of 1 through 10 SQS source ARNs; omit sourceQueueArns entirely for allowAll/denyAll."
  }
}

variable "region" {
  description = "Region override for both queue and created key; null uses the provider region."
  type        = string
  default     = null
}

variable "timeouts" {
  description = "Optional create, update and delete operation timeout strings."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}

variable "tags" {
  description = "Queue and created-key tags; caller values override the additive Name tag."
  type        = map(string)
  default     = {}
}
