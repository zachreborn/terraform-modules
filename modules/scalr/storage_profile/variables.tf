###########################
# Scalr Storage Profile
###########################

variable "storage_profiles" {
  description = <<-EOT
    (Required) Map of Scalr storage profiles (`scalr_storage_profile`) to create, keyed by a caller-chosen
    logical name. Exactly one of aws_s3, azurerm, or google must be set per entry. Sensitive Google
    credentials/encryption keys are intentionally excluded from this variable -- see var.google_credentials
    and var.google_encryption_keys below.
    Fields:
      - name:    (Optional) Name of the storage profile. Defaults to the entry's map key when unset.
      - default: (Optional) Whether this is the default storage profile. Defaults to false.
      - aws_s3:  (Optional) AWS S3 backend settings. Conflicts with azurerm and google. Object fields:
                 - audience:    (Required) The value of the `aud` claim for the identity token.
                 - bucket_name: (Required) AWS S3 bucket name. Bucket must already exist.
                 - role_arn:    (Required) ARN of the IAM role to assume.
                 - region:      (Optional) AWS S3 bucket region.
      - azurerm: (Optional) AzureRM backend settings. Conflicts with aws_s3 and google. Object fields:
                 - audience:        (Required) Azure audience for authentication.
                 - client_id:       (Required) Azure client ID for authentication.
                 - container_name:  (Required) Azure storage container name.
                 - storage_account: (Required) Azure storage account name.
                 - tenant_id:       (Required) Azure tenant ID for authentication.
      - google:  (Optional) Google Cloud Storage backend settings. Conflicts with aws_s3 and azurerm. Object
                 fields:
                 - storage_bucket: (Required) Google Storage bucket name. Bucket must already exist.
                 - project:        (Optional) Google Cloud project ID.
                 (The `credentials` and `encryption_key` attributes are set via var.google_credentials /
                 var.google_encryption_keys, keyed by this same entry's map key.)
  EOT
  type = map(object({
    name    = optional(string)
    default = optional(bool, false)
    aws_s3 = optional(object({
      audience    = string
      bucket_name = string
      role_arn    = string
      region      = optional(string)
    }))
    azurerm = optional(object({
      audience        = string
      client_id       = string
      container_name  = string
      storage_account = string
      tenant_id       = string
    }))
    google = optional(object({
      storage_bucket = string
      project        = optional(string)
    }))
  }))

  validation {
    condition = alltrue([
      for k, v in var.storage_profiles : length([
        for backend in [v.aws_s3, v.azurerm, v.google] : backend if backend != null
      ]) == 1
    ])
    error_message = "Each storage_profiles entry must set exactly one of aws_s3, azurerm, or google."
  }
}

variable "google_credentials" {
  description = <<-EOT
    (Optional) Map of Google Cloud Storage service account JSON key content (the `credentials` attribute of
    the storage profile's google block), keyed by the same keys as var.storage_profiles. Only relevant for
    entries that set google. Kept as a separate, always-sensitive variable rather than an attribute nested
    inside var.storage_profiles, since OpenTofu/Terraform cannot mark a single attribute of an object-typed
    variable as sensitive -- only whole variables can be marked sensitive.
  EOT
  type        = map(string)
  sensitive   = true
  default     = {}
}

variable "google_encryption_keys" {
  description = <<-EOT
    (Optional) Map of Google Cloud Storage customer-supplied encryption keys (the `encryption_key` attribute
    of the storage profile's google block; must be exactly 32 bytes, base64-encoded), keyed by the same keys
    as var.storage_profiles. Only relevant for entries that set google.
  EOT
  type        = map(string)
  sensitive   = true
  default     = {}
}
