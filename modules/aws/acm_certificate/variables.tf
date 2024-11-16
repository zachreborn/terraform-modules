variable "domain_name" {
  type        = string
  description = "(Required) A domain name for which the certificate should be issued"
}

variable "validation_method" {
  type        = string
  description = "(Required) Which method to use for validation. DNS or EMAIL are valid, NONE can be used for certificates that were imported into ACM and then into Terraform."
  default     = "DNS"
}

variable "subject_alternative_names" {
  type        = list(string)
  description = "(Optional) A list of domains that should be SANs in the issued certificate"
  default     = null
}

variable "key_algorithm" {
  type        = string
  description = "(Optional) Specifies the algorithm of the public and private key pair that your Amazon issued certificate uses to encrypt data. Valid options are: RSA_1024, RSA_2048, RSA_3072, RSA_4096, EC_prime256v1, EC_secp384r1, EC_secp521r1. See ACM Certificate documentation for more details - https://docs.aws.amazon.com/acm/latest/userguide/acm-certificate-characteristics.html."
  default     = "EC_prime256v1"
  validation {
    condition     = can(regex("^(RSA_1024|RSA_2048|RSA_3072|RSA_4096|EC_prime256v1|EC_secp384r1|EC_secp521r1)$", var.key_algorithm))
    error_message = "Invalid key_algorithm specified. Must be one of: RSA_1024, RSA_2048, RSA_3072, RSA_4096, EC_prime256v1, EC_secp384r1, EC_secp521r1."
  }
}

variable "tags" {
  type        = map(any)
  description = "(Optional) A mapping of tags to assign to the resource."
  default     = null
}
