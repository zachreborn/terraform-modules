###########################
# Scalr SSH Key
###########################

variable "ssh_keys" {
  description = <<-EOT
    (Required) Map of Scalr SSH keys (`scalr_ssh_key`) to create, keyed by a caller-chosen logical name.
    This variable intentionally excludes the actual private key content -- see var.private_keys below.
    Fields:
      - name:         (Optional) Name of the SSH key, must be unique within an account. Defaults to the
                      entry's map key when unset.
      - account_id:   (Optional) ID of the account the SSH key belongs to, in the format `acc-<RANDOM STRING>`.
      - environments: (Optional) Set of environment IDs where the SSH key can be used. Use ["*"] to share
                      with all environments.
  EOT
  type = map(object({
    name         = optional(string)
    account_id   = optional(string)
    environments = optional(set(string))
  }))
}

variable "private_keys" {
  description = <<-EOT
    (Required) Map of SSH private key content (the `private_key` attribute of `scalr_ssh_key`), keyed by the
    same keys as var.ssh_keys. Kept as a separate, always-sensitive variable rather than an attribute nested
    inside var.ssh_keys, since OpenTofu/Terraform cannot mark a single attribute of an object-typed variable as
    sensitive -- only whole variables can be marked sensitive. Splitting the key out keeps the rest of each
    entry's metadata (name, account_id, environments) visible in plan output while still guaranteeing the
    private key content is never displayed.
    An entry with no matching key here resolves to a null private_key, which the provider rejects as a
    required attribute.
  EOT
  type        = map(string)
  sensitive   = true
}
