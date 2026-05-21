###########################
# S3 Bucket Variables
###########################

variable "bucket" {
  type        = string
  description = "(Required) Fixed name for the centralized S3 access log bucket. Used as a fixed name (not prefix) to support import capability. Must be lowercase, 3–63 characters."
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.\\-]{1,61}[a-z0-9]$", var.bucket))
    error_message = "The bucket name must be lowercase, between 3 and 63 characters, and may only contain letters, numbers, hyphens, and dots."
  }
}

variable "bucket_force_destroy" {
  type        = bool
  description = "(Optional) When true, all objects (including locked objects) are deleted from the bucket when the bucket is destroyed so that the bucket can be destroyed without error. Defaults to false."
  default     = false
  validation {
    condition     = can(regex("true|false", var.bucket_force_destroy))
    error_message = "The value must be true or false."
  }
}

###########################
# Versioning Variables
###########################

variable "enable_versioning" {
  type        = bool
  description = "(Optional) Enable versioning on the access log bucket. When enabled, multiple versions of objects are retained. Defaults to false."
  default     = false
  validation {
    condition     = can(regex("true|false", var.enable_versioning))
    error_message = "The value must be true or false."
  }
}

###########################
# Lifecycle Variables
###########################

variable "lifecycle_rules" {
  description = "(Optional) Configuration of object lifecycle management. Can have several rules as a list of maps where each map is the lifecycle rule configuration. Set to null to disable lifecycle rules."
  type        = any
  default     = null
}

###########################
# Global Variables
###########################

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the bucket."
  default     = {}
}
