###########################
# Replication Configuration Template Variables
###########################

variable "templates" {
  type = map(object({
    associate_default_security_group = optional(bool, false)
    auto_replicate_new_disks         = optional(bool, true)
    bandwidth_throttling             = optional(number, 0)
    create_public_ip                 = optional(bool, false)
    data_plane_routing               = optional(string, "PRIVATE_IP")
    default_large_staging_disk_type  = optional(string, "GP3")
    ebs_encryption                   = optional(string)
    ebs_encryption_key_arn           = optional(string)
    name                             = optional(string)
    pit_policy = optional(list(object({
      enabled            = optional(bool, true)
      interval           = number
      retention_duration = number
      rule_id            = optional(number)
      units              = string
      })), [
      {
        enabled            = true
        interval           = 10
        retention_duration = 60
        rule_id            = 1
        units              = "MINUTE"
      },
      {
        enabled            = true
        interval           = 1
        retention_duration = 24
        rule_id            = 2
        units              = "HOUR"
      },
      {
        enabled            = true
        interval           = 1
        retention_duration = 3
        rule_id            = 3
        units              = "DAY"
      },
    ])
    region                                  = optional(string)
    replication_server_instance_type        = optional(string, "t3.small")
    replication_servers_security_groups_ids = optional(list(string), [])
    staging_area_subnet_id                  = string
    staging_area_tags                       = optional(map(string))
    tags                                    = optional(map(string))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      update = optional(string)
    }))
    use_dedicated_replication_server = optional(bool, false)
  }))
  description = <<-EOT
    (Optional) Map of Elastic Disaster Recovery replication configuration templates to create, keyed by
    logical name. When an entry omits `ebs_encryption` / `ebs_encryption_key_arn`, this module fills them
    in from the KMS key it creates (or the `kms_key_arn` supplied) unless `create_kms_key` is false and no
    `kms_key_arn` is set, in which case the entry falls back to DEFAULT (AWS-managed) EBS encryption. See
    ./replication_configuration_template/variables.tf for the full per-attribute documentation.
  EOT
  default     = {}
}

###########################
# KMS Key Variables
###########################

variable "create_kms_key" {
  type        = bool
  description = "(Optional) Whether to create a customer managed KMS key for encrypting the replication staging area's EBS volumes and snapshots. Mutually exclusive with kms_key_arn."
  default     = true
}

variable "kms_key_arn" {
  type        = string
  description = "(Optional) ARN of an existing customer managed KMS key to use instead of creating one. Requires create_kms_key to be false."
  default     = null
}

variable "kms_key_name_prefix" {
  type        = string
  description = "(Optional) Alias name prefix for the KMS key this module creates. Only used when create_kms_key is true."
  default     = "drs-staging-area"
}

variable "kms_key_description" {
  type        = string
  description = "(Optional) Description for the KMS key this module creates. Only used when create_kms_key is true."
  default     = "Customer managed key used to encrypt the AWS Elastic Disaster Recovery replication staging area."
}

variable "kms_key_deletion_window_in_days" {
  type        = number
  description = "(Optional) Deletion window, in days, for the KMS key this module creates. Only used when create_kms_key is true."
  default     = 30
}

variable "kms_key_enable_key_rotation" {
  type        = bool
  description = "(Optional) Whether automatic key rotation is enabled for the KMS key this module creates. Only used when create_kms_key is true."
  default     = true
}

variable "kms_key_policy" {
  type        = string
  description = "(Optional) A valid policy JSON document for the KMS key this module creates. Only used when create_kms_key is true."
  default     = null
}

###########################
# Initialization Variables
###########################

variable "create_initialization" {
  type        = bool
  description = "(Optional) Whether to manage the Elastic Disaster Recovery initialization submodule (service roles, instance profiles, and the service-linked role) at all. Set this to false when DRS has already been initialized outside of Terraform, such as through the console, and you only want this module to manage replication configuration templates."
  default     = true
}

variable "create_service_roles" {
  type        = bool
  description = "(Optional) Whether to create the six Elastic Disaster Recovery service roles and their instance profiles. Set this to false in an account that has already been initialized through the DRS console, since the role names are fixed and would otherwise collide. Ignored when create_initialization is false."
  default     = false
}

variable "create_service_linked_role" {
  type        = bool
  description = "(Optional) Whether to create the AWSServiceRoleForElasticDisasterRecovery service-linked role. Set this to false in an account where the role already exists, since AWS allows only one service-linked role per service per account. Ignored when create_initialization is false."
  default     = false
}

variable "service_linked_role_description" {
  type        = string
  description = "(Optional) Description applied to the AWSServiceRoleForElasticDisasterRecovery service-linked role. Ignored when create_initialization or create_service_linked_role is false."
  default     = "Service-linked role for AWS Elastic Disaster Recovery."
}

variable "initialization_additional_policy_arns" {
  type        = map(list(string))
  description = "(Optional) Extra managed policy ARNs to attach on top of the AWS managed policies the initialization submodule already attaches, keyed by DRS role name. Ignored when create_initialization is false."
  default     = {}
}

variable "initialization_max_session_duration" {
  type        = number
  description = "(Optional) Maximum session duration, in seconds, for each Elastic Disaster Recovery service role. Ignored when create_initialization is false."
  default     = 3600
}

variable "initialization_path" {
  type        = string
  description = "(Optional) IAM path applied to the Elastic Disaster Recovery service roles and instance profiles. Ignored when create_initialization is false."
  default     = "/service-role/"
}

variable "initialization_permissions_boundary" {
  type        = string
  description = "(Optional) ARN of the policy used to set the permissions boundary on each Elastic Disaster Recovery service role. Ignored when create_initialization is false."
  default     = null
}

###########################
# General Variables
###########################

variable "region" {
  type        = string
  description = "(Optional) Region in which to manage the Elastic Disaster Recovery resources created by this module, applied to any template entry that does not set its own region. Defaults to the region set in the provider configuration."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags applied to every resource this module creates directly or through composition, merged with each resource's own Name tag."
  default = {
    terraform = "true"
  }
}
