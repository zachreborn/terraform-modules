###########################
# KMS Variables
###########################

variable "customer_master_key_spec" {
  type        = string
  description = "(Optional) Specifies whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms that the key supports. Valid values: SYMMETRIC_DEFAULT, RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, or ECC_SECG_P256K1. For help with choosing a key spec, see the AWS KMS Developer Guide."
  default     = "SYMMETRIC_DEFAULT"
  validation {
    condition     = can(regex("^(SYMMETRIC_DEFAULT|RSA_2048|RSA_3072|RSA_4096|ECC_NIST_P256|ECC_NIST_P384|ECC_NIST_P521|ECC_SECG_P256K1)$", var.customer_master_key_spec))
    error_message = "The value must be one of SYMMETRIC_DEFAULT, RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, or ECC_SECG_P256K1."
  }
}

variable "description" {
  description = "(Optional) The description of the key as viewed in AWS console."
  default     = null
}

variable "deletion_window_in_days" {
  type        = number
  description = "(Optional) Duration in days after which the key is deleted after destruction of the resource, must be between 7 and 30 days."
  default     = 30
  validation {
    condition     = var.deletion_window_in_days >= 7 && var.deletion_window_in_days <= 30
    error_message = "The value must be between 7 and 30 days."
  }
}

variable "enable_key_rotation" {
  type        = bool
  description = "(Optional) Specifies whether key rotation is enabled."
  default     = true
}

variable "key_usage" {
  type        = string
  description = "(Optional) Specifies the intended use of the key. Defaults to ENCRYPT_DECRYPT, and only symmetric encryption and decryption are supported."
  default     = "ENCRYPT_DECRYPT"
}

variable "is_enabled" {
  type        = bool
  description = "(Optional) Specifies whether the key is enabled."
  default     = true
}

variable "name_prefix" {
  type        = string
  description = "(Required) Creates an unique alias beginning with the specified prefix. The name will automatically include the word alias followed by a forward slash (alias/your_name_prefix)."
}

variable "policy" {
  type        = string
  description = "(Optional) A valid policy JSON document."
  default     = null
}

######################
# Global Variables
######################

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the object."
  default = {
    environment = "prod"
    terraform   = "true"
  }
}
