########################################
# SSM Domain Join Variables
########################################

########################################
# Domain Join Variables
########################################
variable "dns_servers" {
  type        = list(string)
  description = "(Required) DC IPs the joined instance should use for DNS resolution."
  validation {
    condition     = length(var.dns_servers) > 0
    error_message = "dns_servers must contain at least one IP address."
  }
}

variable "domain_name" {
  type        = string
  description = "(Required) FQDN of the domain to join, e.g. corp.example.com."
  validation {
    condition     = can(regex("^[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.domain_name))
    error_message = "domain_name must be a valid fully qualified domain name."
  }
}

variable "secret_arn" {
  type        = string
  description = "(Required) ARN of the Secrets Manager secret holding join credentials. Secret must be JSON-shaped with username and password keys. Cross-account ARNs are supported."
  validation {
    condition     = can(regex("^arn:", var.secret_arn))
    error_message = "secret_arn must be a valid ARN."
  }
}

########################################
# SSM Document Variables
########################################
variable "name" {
  type        = string
  description = "(Optional) Name of the SSM document and base name for the IAM inline policy."
  default     = "ssm-domain-join"
  validation {
    condition     = length(var.name) > 0
    error_message = "name must not be empty."
  }
}

variable "permissions" {
  type = object({
    account_ids = string
    type        = string
  })
  description = "(Optional) Additional sharing permissions for the SSM document. If null, no sharing permissions are applied. type must be Share."
  default     = null
  nullable    = true
  validation {
    condition     = var.permissions == null ? true : contains(["Share"], var.permissions.type)
    error_message = "permissions.type must be Share."
  }
}

variable "target_type" {
  type        = string
  description = "(Optional) Resource type that the SSM document can target, e.g. /AWS::EC2::Instance. If null, no target type restriction is applied."
  default     = null
  validation {
    condition     = var.target_type == null ? true : can(regex("^\\/[\\w\\.\\-\\:\\/]*$", var.target_type))
    error_message = "target_type must be a valid resource type path, e.g. /AWS::EC2::Instance."
  }
}

variable "version_name" {
  type        = string
  description = "(Optional) Human-readable version name for the SSM document. If null, no version name is assigned."
  default     = null
  validation {
    condition     = var.version_name == null ? true : length(var.version_name) > 0
    error_message = "version_name must not be empty."
  }
}

########################################
# SSM Association Variables
########################################
variable "apply_only_at_cron_interval" {
  type        = bool
  description = "(Optional) When true, the association runs only at the cron interval specified by schedule_expression and not on instance start."
  default     = false
  validation {
    condition     = can(regex("^(true|false)$", tostring(var.apply_only_at_cron_interval)))
    error_message = "apply_only_at_cron_interval must be true or false."
  }
}

variable "association_name" {
  type        = string
  description = "(Optional) Descriptive name for the SSM association. If null, AWS assigns a default name."
  default     = null
  validation {
    condition     = var.association_name == null ? true : length(var.association_name) > 0
    error_message = "association_name must not be empty."
  }
}

variable "compliance_severity" {
  type        = string
  description = "(Optional) Compliance severity reported when instances are non-compliant. Valid values are CRITICAL, HIGH, MEDIUM, LOW, UNSPECIFIED."
  default     = "UNSPECIFIED"
  validation {
    condition     = contains(["CRITICAL", "HIGH", "MEDIUM", "LOW", "UNSPECIFIED"], var.compliance_severity)
    error_message = "compliance_severity must be one of: CRITICAL, HIGH, MEDIUM, LOW, UNSPECIFIED."
  }
}

variable "document_version" {
  type        = string
  description = "(Optional) SSM document version to run. Valid values are $Default, $Latest, or a numeric version string. If null, the default version is used."
  default     = null
  validation {
    condition     = var.document_version == null ? true : can(regex("^(\\$Default|\\$Latest|[0-9]+)$", var.document_version))
    error_message = "document_version must be null, $Default, $Latest, or a numeric version string."
  }
}

variable "max_concurrency" {
  type        = string
  description = "(Optional) Maximum number or percentage of targets to run the association on simultaneously, e.g. 10 or 10%. If null, no concurrency limit is applied."
  default     = null
  validation {
    condition     = var.max_concurrency == null ? true : can(regex("^[0-9]+%?$", var.max_concurrency))
    error_message = "max_concurrency must be null, a positive integer, or a percentage string such as 10%."
  }
}

variable "max_errors" {
  type        = string
  description = "(Optional) Maximum number or percentage of errors allowed before the association stops, e.g. 10 or 10%. If null, no error limit is applied."
  default     = null
  validation {
    condition     = var.max_errors == null ? true : can(regex("^[0-9]+%?$", var.max_errors))
    error_message = "max_errors must be null, a positive integer, or a percentage string such as 10%."
  }
}

variable "output_location_s3_bucket_name" {
  type        = string
  description = "(Optional) Name of the S3 bucket to store SSM association output. If null, output is not saved to S3."
  default     = null
  validation {
    condition     = var.output_location_s3_bucket_name == null ? true : length(var.output_location_s3_bucket_name) > 0
    error_message = "output_location_s3_bucket_name must not be empty."
  }
}

variable "output_location_s3_key_prefix" {
  type        = string
  description = "(Optional) S3 key prefix for SSM association output. If null, no key prefix is applied."
  default     = null
  validation {
    condition     = var.output_location_s3_key_prefix == null ? true : length(var.output_location_s3_key_prefix) > 0
    error_message = "output_location_s3_key_prefix must not be empty."
  }
}

variable "output_location_s3_region" {
  type        = string
  description = "(Optional) AWS region of the S3 bucket for SSM association output. If null, the region of the association is used."
  default     = null
  validation {
    condition     = var.output_location_s3_region == null ? true : can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.output_location_s3_region))
    error_message = "output_location_s3_region must be null or a valid AWS region, e.g. us-east-1."
  }
}

variable "schedule_expression" {
  type        = string
  description = "(Optional) Cron or rate expression controlling how often the association runs, e.g. rate(30 minutes) or cron(0 2 * * ? *). If null, the association runs once on instance launch."
  default     = null
  validation {
    condition     = var.schedule_expression == null ? true : can(regex("^(cron|rate)\\(", var.schedule_expression))
    error_message = "schedule_expression must be null or a valid cron or rate expression."
  }
}

variable "schedule_offset" {
  type        = number
  description = "(Optional) Number of days to wait after the scheduled day to run the association. Valid values are 1 through 6. If null, no offset is applied. Only applicable when schedule_expression is a cron expression."
  default     = null
  validation {
    condition     = var.schedule_offset == null ? true : (var.schedule_offset >= 1 && var.schedule_offset <= 6)
    error_message = "schedule_offset must be null or a number between 1 and 6."
  }
}

variable "sync_compliance" {
  type        = string
  description = "(Optional) Compliance reporting mode for the association. Valid values are AUTO and MANUAL."
  default     = "AUTO"
  validation {
    condition     = contains(["AUTO", "MANUAL"], var.sync_compliance)
    error_message = "sync_compliance must be one of: AUTO, MANUAL."
  }
}

variable "targets" {
  type = list(object({
    key    = string
    values = list(string)
  }))
  description = "(Required) List of target blocks specifying which EC2 instances receive the association. Each target requires a key (e.g. tag:ad_join) and a list of matching values."
  validation {
    condition     = length(var.targets) > 0
    error_message = "targets must contain at least one target."
  }
}

variable "wait_for_success_timeout_seconds" {
  type        = number
  description = "(Optional) Number of seconds to wait for the association to reach a success status. If null, Terraform does not wait for the association to succeed."
  default     = null
  validation {
    condition     = var.wait_for_success_timeout_seconds == null ? true : var.wait_for_success_timeout_seconds > 0
    error_message = "wait_for_success_timeout_seconds must be null or a positive number."
  }
}

########################################
# IAM Variables
########################################
variable "instance_role_name" {
  type        = string
  description = "(Required) Name of the EC2 IAM role to grant secretsmanager:GetSecretValue on secret_arn."
  validation {
    condition     = length(var.instance_role_name) > 0
    error_message = "instance_role_name must not be empty."
  }
}

variable "name_prefix" {
  type        = string
  description = "(Optional) Creates a unique name for the IAM inline policy using this prefix instead of name. Conflicts with name for the IAM policy. If null, name is used."
  default     = null
  validation {
    condition     = var.name_prefix == null ? true : length(var.name_prefix) > 0
    error_message = "name_prefix must not be empty."
  }
}

########################################
# Common Variables
########################################
variable "tags" {
  type        = map(string)
  description = "(Optional) Map of tags to assign to the resources."
  default     = {}
}
