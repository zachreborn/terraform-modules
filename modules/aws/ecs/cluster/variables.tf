###########################
# Cluster Variables
###########################

variable "name" {
  description = "(Required) The name of the ECS cluster and the value of its `Name` tag."
  type        = string
}

variable "container_insights" {
  description = "(Optional) Value for the `containerInsights` cluster setting. Valid values are `enabled`, `enhanced`, and `disabled`. Defaults to `enabled` for secure, observable defaults."
  type        = string
  default     = "enabled"
}

variable "additional_settings" {
  description = "(Optional) Additional `setting` blocks to apply to the cluster, beyond `containerInsights`."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "service_connect_namespace_arn" {
  description = "(Optional) The Cloud Map namespace ARN used for the cluster's `service_connect_defaults`. When null, no default Service Connect namespace is configured."
  type        = string
  default     = null
}

###########################
# Capacity Provider Variables
###########################

variable "capacity_providers" {
  description = "(Optional) List of capacity provider names to associate with the cluster via aws_ecs_cluster_capacity_providers."
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

variable "default_capacity_provider_strategy" {
  description = "(Optional) The default capacity provider strategy for the cluster. Defaults to a Fargate-weighted strategy."
  type = list(object({
    capacity_provider = string
    base              = optional(number)
    weight            = optional(number)
  }))
  default = [
    {
      capacity_provider = "FARGATE"
      base              = 1
      weight            = 100
    }
  ]
}

###########################
# Execute Command Logging Variables
###########################

variable "enable_execute_command_logging" {
  description = "(Optional) Whether to configure encrypted ECS Exec (execute-command) logging on the cluster. Defaults to true."
  type        = bool
  default     = true
}

variable "execute_command_logging" {
  description = "(Optional) The log setting to use for redirecting logs for ECS Exec results. Valid values are `NONE`, `DEFAULT`, and `OVERRIDE`. Defaults to `OVERRIDE`."
  type        = string
  default     = "OVERRIDE"
}

variable "create_kms_key" {
  description = "(Optional) Whether to create a customer-managed KMS key (via modules/aws/kms) for exec-command logging and managed storage encryption. Defaults to true."
  type        = bool
  default     = true
}

variable "kms_key_arn" {
  description = "(Optional) Bring-your-own CMK ARN for exec-command logging. Used when `create_kms_key = false`."
  type        = string
  default     = null
}

variable "create_cloud_watch_log_group" {
  description = "(Optional) Whether to create the exec-command CloudWatch log group (via modules/aws/cloudwatch/log_group). Defaults to true."
  type        = bool
  default     = true
}

variable "cloud_watch_log_group_name" {
  description = "(Optional) Name of an existing CloudWatch log group to send exec-command logs to. Used when `create_cloud_watch_log_group = false`."
  type        = string
  default     = null
}

variable "cloud_watch_encryption_enabled" {
  description = "(Optional) Whether to enable encryption on the CloudWatch logs for exec-command. Defaults to true."
  type        = bool
  default     = true
}

variable "log_group_retention_in_days" {
  description = "(Optional) Retention period, in days, for the created exec-command CloudWatch log group. Defaults to 365."
  type        = number
  default     = 365
}

variable "s3_bucket_name" {
  description = "(Optional) Name of the S3 bucket to send exec-command logs to."
  type        = string
  default     = null
}

variable "s3_key_prefix" {
  description = "(Optional) Optional folder/prefix in the S3 bucket to place exec-command logs."
  type        = string
  default     = null
}

variable "s3_bucket_encryption_enabled" {
  description = "(Optional) Whether to enable encryption on the S3 logs for exec-command. Defaults to true."
  type        = bool
  default     = true
}

###########################
# Managed Storage Variables
###########################

variable "managed_storage_kms_key_arn" {
  description = "(Optional) KMS key ARN used to encrypt Fargate ephemeral (managed) storage. Defaults to the created CMK when `create_kms_key = true`."
  type        = string
  default     = null
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) A map of tags to assign to the cluster and the resources created via composition. A `Name` tag is merged automatically."
  type        = map(string)
  default     = {}
}
