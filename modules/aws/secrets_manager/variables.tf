###########################
# Secrets Manager Variables
###########################

variable "secrets" {
  description = <<-EOT
    (Optional) Map of AWS Secrets Manager secrets to create, keyed by a caller-chosen logical name
    (e.g. "database_credentials"). Defaults to an empty map (no secrets created).
    Fields:
      - name:                             (Optional) Friendly name of the secret. Defaults to the entry's
                                           map key when neither name nor name_prefix is set. Conflicts with
                                           name_prefix.
      - name_prefix:                      (Optional) Creates a unique name beginning with the specified
                                           prefix. Conflicts with name.
      - description:                      (Optional) Description of the secret.
      - recovery_window_in_days:          (Optional) Number of days AWS Secrets Manager waits before it can
                                           delete the secret. Must be 0 (force deletion without recovery) or
                                           between 7 and 30 days. Defaults to 30.
      - policy:                           (Optional) Valid JSON document representing a resource policy
                                           managed inline on the secret. Conflicts with manage_resource_policy,
                                           since both manage the same underlying resource policy.
      - force_overwrite_replica_secret:   (Optional) Whether to overwrite a secret with the same name in the
                                           destination Region during replication. Defaults to false.
      - replica:                          (Optional) List of Regions to replicate this secret to. Each entry
                                           supports: region (Required), kms_key_id (Optional, defaults to the
                                           replica Region's aws/secretsmanager managed key when unset).
      - tags:                             (Optional) Additional tags for this secret, merged with var.tags.
      - create_kms_key:                   (Optional) If true, this module creates a dedicated customer managed
                                           KMS key (via modules/aws/kms) to encrypt this secret. Conflicts with
                                           kms_key_id. Defaults to false, which lets Secrets Manager use the
                                           AWS managed key (aws/secretsmanager) unless kms_key_id is set.
      - kms_key_id:                       (Optional) ARN or ID of a caller-supplied KMS key to encrypt the
                                           secret. Conflicts with create_kms_key.
      - enable_rotation:                  (Optional) Whether to manage automatic rotation for this secret.
                                           Defaults to false. When true, rotation_lambda_arn is required, along
                                           with exactly one of rotation_automatically_after_days or
                                           rotation_schedule_expression.
      - rotation_lambda_arn:               (Optional) ARN of the Lambda function that rotates the secret.
                                           Required when enable_rotation is true. This module does not create
                                           the rotation function itself -- rotation function code is specific
                                           to the secret's credential type, so bring your own function (for
                                           example, one deployed from an AWS-provided rotation template) and
                                           pass its ARN here.
      - rotate_immediately:               (Optional) Whether to rotate the secret immediately upon enabling
                                           rotation, rather than waiting for the next scheduled window. Defaults
                                           to true.
      - rotation_automatically_after_days: (Optional) Number of days between automatic rotations. Conflicts
                                           with rotation_schedule_expression; exactly one is required when
                                           enable_rotation is true.
      - rotation_duration:                (Optional) Length of the rotation window, for example "3h".
      - rotation_schedule_expression:      (Optional) A cron() or rate() expression defining the rotation
                                           schedule. Conflicts with rotation_automatically_after_days; exactly
                                           one is required when enable_rotation is true.
      - manage_resource_policy:           (Optional) Whether to manage this secret's resource policy via a
                                           standalone aws_secretsmanager_secret_policy resource (needed to set
                                           block_public_policy). Defaults to false. Conflicts with policy, since
                                           both manage the same underlying resource policy.
      - resource_policy:                  (Optional) Valid JSON document representing a resource policy.
                                           Required when manage_resource_policy is true.
      - block_public_policy:              (Optional) Validates the resource policy to help prevent broad
                                           access to the secret. Only applies when manage_resource_policy is
                                           true. Defaults to true.
  EOT
  type = map(object({
    name                           = optional(string)
    name_prefix                    = optional(string)
    description                    = optional(string)
    recovery_window_in_days        = optional(number, 30)
    policy                         = optional(string)
    force_overwrite_replica_secret = optional(bool, false)
    replica = optional(list(object({
      region     = string
      kms_key_id = optional(string)
    })), [])
    tags = optional(map(string), {})

    create_kms_key = optional(bool, false)
    kms_key_id     = optional(string)

    enable_rotation                   = optional(bool, false)
    rotation_lambda_arn               = optional(string)
    rotate_immediately                = optional(bool, true)
    rotation_automatically_after_days = optional(number)
    rotation_duration                 = optional(string)
    rotation_schedule_expression      = optional(string)

    manage_resource_policy = optional(bool, false)
    resource_policy        = optional(string)
    block_public_policy    = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.secrets : !(v.name != null && v.name_prefix != null)
    ])
    error_message = "Each secrets entry must not set both name and name_prefix."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets : !(v.create_kms_key && v.kms_key_id != null)
    ])
    error_message = "Each secrets entry must not set both create_kms_key and kms_key_id."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets : v.recovery_window_in_days == 0 || (v.recovery_window_in_days >= 7 && v.recovery_window_in_days <= 30)
    ])
    error_message = "recovery_window_in_days must be 0 or between 7 and 30 days."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets : !v.enable_rotation || v.rotation_lambda_arn != null
    ])
    error_message = "rotation_lambda_arn is required when enable_rotation is true."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets : !v.enable_rotation || (v.rotation_automatically_after_days != null) != (v.rotation_schedule_expression != null)
    ])
    error_message = "Exactly one of rotation_automatically_after_days or rotation_schedule_expression is required when enable_rotation is true."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets : !v.manage_resource_policy || v.resource_policy != null
    ])
    error_message = "resource_policy is required when manage_resource_policy is true."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets : !(v.policy != null && v.manage_resource_policy)
    ])
    error_message = "Each secrets entry must not set both policy and manage_resource_policy; both manage the same underlying resource policy."
  }
}

variable "secret_values" {
  description = <<-EOT
    (Optional) Map of PERSISTED secret values to store, keyed by the same logical name used in var.secrets.
    Entries without a corresponding var.secrets key are ignored. Defaults to an empty map (no secret versions
    created -- useful when the value will be set out-of-band via the console or CLI).

    WARNING: values supplied here are written to the Terraform/OpenTofu state file AND to saved plan files in
    plaintext. For secret material, prefer var.secret_values_wo, which keeps the value out of both. Reserve this
    variable for low-sensitivity values, and pair it with state/plan encryption when used.

    Fields:
      - secret_string:  (Optional) Text data to store. Exactly one of secret_string or secret_binary is
                         required per entry.
      - secret_binary:  (Optional) Base64-encoded binary data to store.
      - version_stages: (Optional) List of staging labels to attach to this version.
  EOT
  type = map(object({
    secret_string  = optional(string)
    secret_binary  = optional(string)
    version_stages = optional(list(string))
  }))
  default   = {}
  sensitive = true

  validation {
    condition = alltrue([
      for k, v in var.secret_values : length([for x in [v.secret_string, v.secret_binary] : x if x != null]) == 1
    ])
    error_message = "Each secret_values entry must set exactly one of secret_string or secret_binary."
  }
}

variable "secret_values_wo" {
  description = <<-EOT
    (Optional) Map of WRITE-ONLY secret values to store, keyed by the same logical name used in var.secrets.
    Defaults to an empty map.

    This is the secure path for real secret material: the value is sent straight to AWS and is never written to
    the state file, a saved plan file, or CLI output. The variable is declared `ephemeral`, so it accepts values
    from ephemeral resources (e.g. `ephemeral "random_password"`) and its value is not persisted in plan files.

    Every key set here must also have a matching entry in var.secret_values_wo_versions, which is the
    non-ephemeral counter that tells the provider when to push a new value.
  EOT
  type        = map(string)
  default     = {}
  sensitive   = true
  ephemeral   = true

  validation {
    condition = alltrue([
      for k in keys(var.secret_values_wo) : contains(keys(var.secret_values_wo_versions), k)
    ])
    error_message = "Every secret_values_wo key must have a matching entry in secret_values_wo_versions; without one the value would be silently ignored."
  }

  validation {
    condition = alltrue([
      for k in keys(var.secret_values_wo_versions) : contains(keys(var.secret_values_wo), k)
    ])
    error_message = "Every secret_values_wo_versions key must have a matching entry in secret_values_wo."
  }
}

variable "secret_values_wo_versions" {
  description = <<-EOT
    (Optional) Map of version counters for var.secret_values_wo, keyed by the same logical name. Defaults to an
    empty map.

    Write-only values produce no plan diff (their prior state is always null), so this counter is what tells the
    provider to push a new value. Increment an entry to rotate that secret; leave it unchanged and the existing
    value is left alone even if secret_values_wo differs. Because this map is NOT ephemeral, its keys are what
    select which secrets receive a write-only version.
  EOT
  type        = map(number)
  default     = {}

  validation {
    condition = alltrue([
      for k in keys(var.secret_values_wo_versions) : contains(keys(var.secrets), k)
    ])
    error_message = "Every secret_values_wo_versions key must match a key in var.secrets."
  }

  validation {
    condition = alltrue([
      for k in keys(var.secret_values_wo_versions) : !contains(keys(var.secret_values), k)
    ])
    error_message = "A secret cannot appear in both secret_values and secret_values_wo; choose the persisted path or the write-only path for each secret."
  }
}

######################
# Global Variables
######################

variable "tags" {
  description = "(Optional) Key-value map of resource tags applied to every secret and composed KMS key, merged with each entry's optional per-secret tags. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(any)
  default     = {}
}
