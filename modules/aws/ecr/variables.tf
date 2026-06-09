###########################
# Resource Variables
###########################

variable "encryption_type" {
  type        = string
  description = "(Optional) The encryption type to use for the ECR repository. Valid values are 'AES256' or 'KMS'. Defaults to 'KMS' for Well-Architected compliance."
  default     = "KMS"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Invalid encryption type. Must be one of 'AES256' or 'KMS'."
  }
}

variable "force_delete" {
  type        = bool
  description = "(Optional) Whether to force delete the repository even if it contains images. Defaults to false."
  default     = false
}

variable "image_tag_mutability" {
  type        = string
  description = "(Optional) The tag mutability setting for the repository. Valid values are 'MUTABLE', 'IMMUTABLE', 'IMMUTABLE_WITH_EXCLUSION', or 'MUTABLE_WITH_EXCLUSION'. Defaults to 'IMMUTABLE' to prevent tag overwrites."
  default     = "IMMUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE", "IMMUTABLE_WITH_EXCLUSION", "MUTABLE_WITH_EXCLUSION"], var.image_tag_mutability)
    error_message = "Invalid image tag mutability setting. Must be one of 'MUTABLE', 'IMMUTABLE', 'IMMUTABLE_WITH_EXCLUSION', or 'MUTABLE_WITH_EXCLUSION'."
  }
}

variable "image_tag_mutability_exclusion_filter" {
  type        = list(string)
  description = "(Optional) A list of tag filter expressions. Tags matching these filters will remain mutable even when the repository is set to IMMUTABLE_WITH_EXCLUSION or MUTABLE_WITH_EXCLUSION. Wildcards (*) match zero or more tag characters. Defaults to null (no exclusions)."
  default     = null
}

variable "kms_key" {
  type        = string
  description = "(Optional) The ARN of the KMS CMK to use when encryption_type is 'KMS'. If not specified, the AWS-managed ECR CMK is used. Must be a valid KMS key ARN. Ignored when encryption_type is 'AES256'."
  default     = null
  validation {
    condition     = var.kms_key == null || can(regex("^arn:aws[a-z-]*:kms:[^:]+:[0-9]{12}:key/[0-9a-zA-Z-]+$", var.kms_key))
    error_message = "kms_key must be null or a valid KMS key ARN (arn:aws:kms:<region>:<account_id>:key/<key_id>). Multi-region key IDs (mrk-...) are supported."
  }
}

variable "lifecycle_policy" {
  type        = string
  description = "(Optional) A JSON-encoded ECR lifecycle policy document. When set, an aws_ecr_lifecycle_policy resource is created for this repository. Defaults to null (no lifecycle policy)."
  default     = null
}

variable "name" {
  type        = string
  description = "(Required) The name of the ECR repository."
}

variable "repository_policy" {
  type        = string
  description = "(Optional) A JSON-encoded IAM policy document to attach to the repository. When set, an aws_ecr_repository_policy resource is created. Defaults to null (no repository policy)."
  default     = null
}

variable "scan_on_push" {
  type        = bool
  description = "(Optional) Whether to enable automatic image scanning on push. Defaults to true."
  default     = true
}

###########################
# General Variables
###########################

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags to assign to the ECR repository. A 'Name' tag is added by default using the repository name and may be overridden by passing a 'Name' key in this map."
  default = {
    terraform = "true"
  }
}
