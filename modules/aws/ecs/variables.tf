###########################
# Resource Variables
###########################

variable "cluster_name" {
  description = "Name of the cluster (up to 255 letters, numbers, hyphens, and underscores)"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,255}$", var.cluster_name))
    error_message = "Cluster name must be 1-255 characters long and can only contain letters, numbers, hyphens, and underscores."
  }
}

variable "configuration" {
  description = "Configuration for the ECS cluster, including execute command and managed storage configurations"
  type = list(object({
    execute_command_configuration = optional(object({
      kms_key_id = string
      logging    = string
      log_configuration = optional(object({
        cloud_watch_encryption_enabled = bool
        cloud_watch_log_group_name     = string
        s3_bucket_name                 = string
        s3_bucket_encryption_enabled   = bool
        s3_key_prefix                  = string
      }))
    }))
    managed_storage_configuration = optional(object({
      fargate_ephemeral_storage_kms_key_id = string
      kms_key_id                           = string
    }))
  }))
  default = []
}

variable "container_insights" {
  description = "Setting for CloudWatch container insights. Valid are 'enabled', 'enhanced', or 'disabled'"
  type        = string
  default     = ""
  validation {
    condition     = can(regex("^(enabled|enhanced|disabled)$", var.container_insights))
    error_message = "container_insights must be 'enabled', 'enhanced', or 'disabled'."
  }
}

variable "service_connect_default_namespace" {
  description = "The default namespace for service connect which is utilized when a service does not define a service connect configuration. This must be the ARN of the namespace."
  type        = string
  default     = null
  validation {
    condition     = can(regex("^arn:aws:servicediscovery:[a-z]{2}-[a-z]+-[0-9]:[0-9]{12}:namespace/.+$", var.service_connect_default_namespace)) || var.service_connect_default_namespace == null
    error_message = "service_connect_default_namespace must be a valid ARN or null."
  }
}

###########################
# General Variables
###########################

variable "tags" {
  description = "A map of tags to assign to the ECS cluster"
  type        = map(string)
  default = {
    "terraform" = "true"
  }
}
