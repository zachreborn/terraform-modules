###########################
# Resource Variables
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
    logical name. The key is used as the Name tag on both the template and its staging area resources
    unless `name` is set on the entry. Supply this map inline or from a YAML file via `yamldecode()` to
    manage many templates from a single module block.

    Attributes per entry:
      * `associate_default_security_group` - (Optional) Whether to associate the default Elastic Disaster Recovery security group with the template. Defaults to false so replication servers sit behind an explicit security group.
      * `auto_replicate_new_disks` - (Optional) Whether the AWS replication agent automatically replicates newly added disks. Defaults to true so disks added after enrollment are not silently left unprotected.
      * `bandwidth_throttling` - (Optional) Outbound data transfer rate limit for the source server, in Mbps. Defaults to 0 (unthrottled).
      * `create_public_ip` - (Optional) Whether to create a public IP for the recovery instance by default. Defaults to false.
      * `data_plane_routing` - (Optional) Data plane routing mechanism used for replication. Valid values are PUBLIC_IP and PRIVATE_IP. Defaults to PRIVATE_IP.
      * `default_large_staging_disk_type` - (Optional) Staging disk EBS volume type used during replication. Valid values are GP2, GP3, ST1, and AUTO. Defaults to GP3.
      * `ebs_encryption` - (Optional) Type of EBS encryption used during replication. Valid values are DEFAULT, CUSTOM, and NONE (per the DRS API; the Terraform Registry page for this resource omits NONE, but the provider schema and AWS API both accept it). When omitted this resolves to CUSTOM if `ebs_encryption_key_arn` is set and DEFAULT otherwise.
      * `ebs_encryption_key_arn` - (Optional) ARN of the customer managed KMS key used to encrypt the staging area during replication. Required when `ebs_encryption` is CUSTOM.
      * `name` - (Optional) Overrides the map key when building the default Name tag.
      * `pit_policy` - (Optional) Point in time (PIT) snapshot policy rules. Defaults to the three rules AWS mandates. Only the `retention_duration` of rule 3 may be changed.
      * `region` - (Optional) Region in which to manage this template. Defaults to the region set in the provider configuration.
      * `replication_server_instance_type` - (Optional) Instance type used for the replication server. Defaults to t3.small.
      * `replication_servers_security_groups_ids` - (Optional) Security group IDs used by the replication server. Required to be non-empty unless `associate_default_security_group` is true.
      * `staging_area_subnet_id` - (Required) Subnet used by the replication staging area.
      * `staging_area_tags` - (Optional) Tags applied to every resource created in the replication staging area, always merged with a Name tag and the module's `tags`; entry-specific keys take precedence on conflict.
      * `tags` - (Optional) Tags applied to the replication configuration template itself, always merged with a Name tag and the module's `tags`; entry-specific keys take precedence on conflict.
      * `timeouts` - (Optional) Overrides for the resource create, update, and delete timeouts. Each defaults to 20m in the provider.
      * `use_dedicated_replication_server` - (Optional) Whether to use a dedicated replication server in the staging area. Defaults to false.
  EOT
  default     = {}

  validation {
    condition = alltrue([
      for key, template in var.templates :
      contains(["PUBLIC_IP", "PRIVATE_IP"], template.data_plane_routing)
    ])
    error_message = "Each template's data_plane_routing must be either PUBLIC_IP or PRIVATE_IP."
  }

  validation {
    condition = alltrue([
      for key, template in var.templates :
      contains(["GP2", "GP3", "ST1", "AUTO"], template.default_large_staging_disk_type)
    ])
    error_message = "Each template's default_large_staging_disk_type must be one of GP2, GP3, ST1, or AUTO."
  }

  validation {
    condition = alltrue([
      for key, template in var.templates :
      template.ebs_encryption == null || contains(["DEFAULT", "CUSTOM", "NONE"], coalesce(template.ebs_encryption, "DEFAULT"))
    ])
    error_message = "Each template's ebs_encryption must be one of DEFAULT, CUSTOM, or NONE when set."
  }

  validation {
    condition = alltrue([
      for key, template in var.templates :
      template.ebs_encryption != "CUSTOM" || template.ebs_encryption_key_arn != null
    ])
    error_message = "A template with ebs_encryption set to CUSTOM must also set ebs_encryption_key_arn."
  }

  validation {
    condition = alltrue([
      for key, template in var.templates :
      template.associate_default_security_group || length(template.replication_servers_security_groups_ids) > 0
    ])
    error_message = "A template must supply at least one entry in replication_servers_security_groups_ids unless associate_default_security_group is true."
  }

  validation {
    condition = alltrue([
      for key, template in var.templates :
      template.bandwidth_throttling >= 0
    ])
    error_message = "Each template's bandwidth_throttling must be zero (unthrottled) or greater."
  }

  # A nonempty-list check alone would let a single rule, duplicate rule_ids,
  # omitted rule_id values, or an extra/foreign rule slip past the rule 1/2/3
  # exact-value validations below, since those only constrain a rule IF its
  # rule_id happens to equal 1, 2, or 3. AWS's fixed PIT policy requires
  # exactly rule_ids 1, 2, and 3, each exactly once; enforce that set directly.
  #
  # sort() returns list(string), which compares unequal to a tuple literal via
  # == even when their elements match (a real Terraform/OpenTofu cty quirk);
  # join() side-steps this by comparing plain strings. tostring() is injective
  # over integers, so a match against "1,2,3" is only possible when the
  # underlying rule_id multiset is exactly {1, 2, 3}.
  validation {
    condition = alltrue([
      for key, template in var.templates :
      join(",", sort([for rule in template.pit_policy : tostring(coalesce(rule.rule_id, -1))])) == "1,2,3"
    ])
    error_message = "Each template's pit_policy must declare exactly three rules with rule_id 1, 2, and 3 (each exactly once), per AWS's fixed PIT policy requirement."
  }

  validation {
    condition = alltrue(flatten([
      for key, template in var.templates : [
        for rule in template.pit_policy :
        contains(["MINUTE", "HOUR", "DAY"], rule.units)
      ]
    ]))
    error_message = "Each pit_policy rule's units must be one of MINUTE, HOUR, or DAY."
  }

  validation {
    condition = alltrue(flatten([
      for key, template in var.templates : [
        for rule in template.pit_policy :
        rule.rule_id != 1 || (rule.interval == 10 && rule.units == "MINUTE" && rule.retention_duration == 60)
      ]
    ]))
    error_message = "AWS only accepts pit_policy rule 1 as interval 10, units MINUTE, retention_duration 60."
  }

  validation {
    condition = alltrue(flatten([
      for key, template in var.templates : [
        for rule in template.pit_policy :
        rule.rule_id != 2 || (rule.interval == 1 && rule.units == "HOUR" && rule.retention_duration == 24)
      ]
    ]))
    error_message = "AWS only accepts pit_policy rule 2 as interval 1, units HOUR, retention_duration 24."
  }

  validation {
    condition = alltrue(flatten([
      for key, template in var.templates : [
        for rule in template.pit_policy :
        rule.rule_id != 3 || (rule.interval == 1 && rule.units == "DAY")
      ]
    ]))
    error_message = "AWS only accepts pit_policy rule 3 as interval 1, units DAY; only its retention_duration may be changed."
  }
}

###########################
# General Variables
###########################

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags merged with a Name tag and applied to each template and its staging area resources. Always merged in, even when an entry sets its own tags / staging_area_tags; entry-specific keys take precedence on conflict."
  default = {
    terraform = "true"
  }
}
