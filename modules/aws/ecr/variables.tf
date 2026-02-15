###########################
# Resource Variables
###########################

variable "enable_encryption" {
  type        = bool
  description = "Whether to enable encryption for the ECR repository."
  default     = false
}

variable "encryption_type" {
  type        = string
  description = "The encryption type to use for the ECR repository. Must be one of 'AES256' or 'KMS'."
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Invalid encryption type. Must be one of 'AES256' or 'KMS'."
  }
}

variable "kms_key" {
  type        = string
  description = "The ARN of the KMS key to use when encryption_type is KMS. Must be a valid KMS ARN. If not specified, uses the default AWS managed key for ECR."
  default     = null
  validation {
    condition     = can(regex("arn:aws:kms:[^:]+:[0-9]+:key/[0-9a-f-]+", var.kms_key)) || var.kms_key == null
    error_message = "Invalid KMS key ARN format."
  }
}

variable "force_delete" {
  type        = bool
  description = "Whether to force delete the repository if images exist."
  default     = false
}

variable "image_tag_mutability" {
  type        = string
  description = "The tag mutability setting for the repository. Must be one of 'MUTABLE', 'IMMUTABLE', 'IMMUTABLE_WITH_EXCLUSION', or 'MUTABLE_WITH_EXCLUSION'."
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE", "IMMUTABLE_WITH_EXCLUSION", "MUTABLE_WITH_EXCLUSION"], var.image_tag_mutability)
    error_message = "Invalid image tag mutability setting. Must be one of 'MUTABLE', 'IMMUTABLE', 'IMMUTABLE_WITH_EXCLUSION', or 'MUTABLE_WITH_EXCLUSION'."
  }
}

variable "image_tag_mutability_exclusion_filter" {
  type        = list(string)
  description = "A list of tags. Tags that match these filters will be mutable (can be overwritten). Using wildcards (*) will match zero or more image tag characters."
  default     = null
}

variable "name" {
  type        = string
  description = "The name of the ECR repository."
}

###########################
# General Variables
###########################

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the ECR repository."
  default = {
    terraform = "true"
  }
}
