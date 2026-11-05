###########################
# Inputs
###########################
variable "tags" {
  description = "Shared table tags; per-table tags override these and the physical-name Name tag."
  type        = map(string)
  default     = {}
}

variable "tables" {
  description = "Tables keyed by stable logical identity. Only indexed keys belong in attribute; TTL/item fields do not. Optional advanced blocks are omitted when null."
  type = map(object({
    name                        = string
    region                      = optional(string)
    billing_mode                = optional(string, "PAY_PER_REQUEST")
    hash_key                    = optional(string)
    range_key                   = optional(string)
    attribute                   = optional(set(object({ name = string, type = string })), [])
    read_capacity               = optional(number)
    write_capacity              = optional(number)
    deletion_protection_enabled = optional(bool, true)
    table_class                 = optional(string, "STANDARD")
    tags                        = optional(map(string), {})
    stream_enabled              = optional(bool, false)
    stream_view_type            = optional(string)
    ttl = optional(object({
      attribute_name = optional(string)
      enabled        = optional(bool, false)
    }))
    point_in_time_recovery = optional(object({
      enabled                 = optional(bool, true)
      recovery_period_in_days = optional(number)
    }), {})
    server_side_encryption = optional(object({
      enabled     = optional(bool, true)
      kms_key_arn = optional(string)
    }), {})
    on_demand_throughput = optional(object({
      max_read_request_units  = optional(number)
      max_write_request_units = optional(number)
    }))
    warm_throughput = optional(object({
      read_units_per_second  = optional(number)
      write_units_per_second = optional(number)
    }))
    global_secondary_index = optional(set(object({
      name               = string
      projection_type    = string
      hash_key           = optional(string)
      range_key          = optional(string)
      key_schema         = optional(list(object({ attribute_name = string, key_type = string })), [])
      non_key_attributes = optional(set(string), [])
      read_capacity      = optional(number)
      write_capacity     = optional(number)
      on_demand_throughput = optional(object({
        max_read_request_units  = optional(number)
        max_write_request_units = optional(number)
      }))
      warm_throughput = optional(object({
        read_units_per_second  = optional(number)
        write_units_per_second = optional(number)
      }))
    })), [])
    local_secondary_index = optional(set(object({
      name               = string
      range_key          = string
      projection_type    = string
      non_key_attributes = optional(list(string), [])
    })), [])
    replica = optional(set(object({
      region_name                 = string
      kms_key_arn                 = optional(string)
      point_in_time_recovery      = optional(bool, true)
      propagate_tags              = optional(bool, true)
      deletion_protection_enabled = optional(bool, true)
      consistency_mode            = optional(string, "EVENTUAL")
    })), [])
    global_table_witness     = optional(object({ region_name = string }))
    restore_backup_arn       = optional(string)
    restore_source_name      = optional(string)
    restore_source_table_arn = optional(string)
    restore_date_time        = optional(string)
    restore_to_latest_time   = optional(bool)
    import_table = optional(object({
      input_format           = string
      input_compression_type = optional(string)
      s3_bucket_source = object({
        bucket       = string
        bucket_owner = optional(string)
        key_prefix   = optional(string)
      })
      input_format_options = optional(object({
        csv = optional(object({
          delimiter   = optional(string)
          header_list = optional(set(string))
        }))
      }))
    }))
    timeouts = optional(object({
      create = optional(string)
      update = optional(string)
      delete = optional(string)
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for t in var.tables : t != null])
    error_message = "Table entries must not be null."
  }
  validation {
    condition     = alltrue([for t in var.tables : try(contains(["PAY_PER_REQUEST", "PROVISIONED"], t.billing_mode), false)])
    error_message = "billing_mode must be PAY_PER_REQUEST or PROVISIONED."
  }
  validation {
    condition     = alltrue([for t in var.tables : try(contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], t.table_class), false)])
    error_message = "table_class must be STANDARD or STANDARD_INFREQUENT_ACCESS."
  }
  validation {
    condition     = alltrue([for t in var.tables : try(alltrue([for a in t.attribute : contains(["S", "N", "B"], a.type)]), false)])
    error_message = "Attribute types must be S, N, or B."
  }
  validation {
    condition     = alltrue([for t in var.tables : try(length(compact([t.restore_backup_arn, t.restore_source_name, t.restore_source_table_arn])) > 0 ? true : length(trimspace(coalesce(t.hash_key, " "))) > 0, false)])
    error_message = "Creation and import require a nonempty hash_key; restores may omit it."
  }
  validation {
    condition     = alltrue([for t in var.tables : try(length(distinct([for a in t.attribute : a.name])) == length(t.attribute), false)])
    error_message = "Attribute names must be unique."
  }
  validation {
    condition = alltrue([for t in var.tables : try(
      length(setsubtract(toset(compact(concat([t.hash_key, t.range_key], [for i in t.local_secondary_index : i.range_key], flatten([for i in t.global_secondary_index : concat([i.hash_key, i.range_key], [for k in i.key_schema : k.attribute_name])])))), toset([for a in t.attribute : a.name]))) == 0,
    false)])
    error_message = "Every configured table and index key must have an attribute definition."
  }
  validation {
    condition = alltrue([for t in var.tables : try(
      length(setsubtract(toset([for a in t.attribute : a.name]), toset(compact(concat([t.hash_key, t.range_key], [for i in t.local_secondary_index : i.range_key], flatten([for i in t.global_secondary_index : concat([i.hash_key, i.range_key], [for k in i.key_schema : k.attribute_name])])))))) == 0,
    false)])
    error_message = "Do not define unused attributes: only table/index keys belong in attribute, not TTL or item fields."
  }
  validation {
    condition = alltrue([for t in var.tables : try(
      length(distinct(concat([for i in t.global_secondary_index : i.name], [for i in t.local_secondary_index : i.name]))) == length(t.global_secondary_index) + length(t.local_secondary_index) &&
      alltrue([for n in concat([for i in t.global_secondary_index : i.name], [for i in t.local_secondary_index : i.name]) : can(regex("^[A-Za-z0-9_.-]{3,255}$", n))]),
    false)])
    error_message = "Index names must be distinct and contain 3..255 letters, digits, underscores, dots, or hyphens."
  }
  validation {
    condition     = alltrue([for t in var.tables : try(length(t.local_secondary_index) == 0 ? true : length(trimspace(coalesce(t.range_key, " "))) > 0, false)])
    error_message = "Local secondary indexes require the base table range_key."
  }
  validation {
    # Only the first entry is the base table; explicitly configured GSIs never inherit units.
    condition = alltrue([for t in var.tables : try(alltrue([
      for position, x in concat([{ read_capacity = t.read_capacity, write_capacity = t.write_capacity }], [for i in t.global_secondary_index : { read_capacity = i.read_capacity, write_capacity = i.write_capacity }]) :
      t.billing_mode == "PAY_PER_REQUEST" ? (x.read_capacity == null && x.write_capacity == null) :
      (position == 0 && length(compact([t.restore_backup_arn, t.restore_source_name, t.restore_source_table_arn])) > 0 && x.read_capacity == null && x.write_capacity == null ? true :
      try(x.read_capacity > 0 && floor(x.read_capacity) == x.read_capacity && x.write_capacity > 0 && floor(x.write_capacity) == x.write_capacity, false))
    ]), false)])
    error_message = "PROVISIONED tables and GSIs require positive integer read/write capacities; only restored base tables may omit both. PAY_PER_REQUEST forbids them."
  }
  validation {
    condition = alltrue([for t in var.tables : try(alltrue([
      for x in concat([t.on_demand_throughput], [for i in t.global_secondary_index : i.on_demand_throughput]) :
      x == null ? true : (t.billing_mode == "PAY_PER_REQUEST" && alltrue([for n in [x.max_read_request_units, x.max_write_request_units] : n == null ? true : (n == -1 || (n > 0 && floor(n) == n))]))
    ]), false)])
    error_message = "On-demand caps apply only to PAY_PER_REQUEST and must be -1 or positive integers."
  }
  validation {
    condition = alltrue([for t in var.tables : try(alltrue([
      for x in concat([t.warm_throughput], [for i in t.global_secondary_index : i.warm_throughput]) :
      x == null ? true : ((x.read_units_per_second == null ? true : x.read_units_per_second >= 12000 && floor(x.read_units_per_second) == x.read_units_per_second) &&
      (x.write_units_per_second == null ? true : x.write_units_per_second >= 4000 && floor(x.write_units_per_second) == x.write_units_per_second))
    ]), false)])
    error_message = "Warm reads must be integers >=12000 and writes integers >=4000."
  }
  validation {
    condition     = alltrue([for t in var.tables : try(t.point_in_time_recovery.recovery_period_in_days == null ? true : (t.point_in_time_recovery.recovery_period_in_days >= 1 && t.point_in_time_recovery.recovery_period_in_days <= 35 && floor(t.point_in_time_recovery.recovery_period_in_days) == t.point_in_time_recovery.recovery_period_in_days), false)])
    error_message = "Recovery retention must be an integer from 1 through 35 days."
  }
  validation {
    condition     = alltrue([for t in var.tables : try(t.ttl == null ? true : (t.ttl.enabled ? length(trimspace(coalesce(t.ttl.attribute_name, " "))) > 0 : true), false)])
    error_message = "Enabled TTL requires a nonempty attribute_name; disabled TTL may retain its name."
  }
  validation {
    condition     = alltrue([for t in var.tables : try(t.stream_enabled ? contains(["KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"], coalesce(t.stream_view_type, " ")) : t.stream_view_type == null, false)])
    error_message = "Enabled streams require a valid view; stream_view_type must be null when streams are disabled."
  }
  validation {
    condition = alltrue([for t in var.tables : try(alltrue([
      for i in concat(tolist(t.global_secondary_index), [for l in t.local_secondary_index : { projection_type = l.projection_type, non_key_attributes = toset(l.non_key_attributes) }]) :
      contains(["ALL", "KEYS_ONLY", "INCLUDE"], i.projection_type) && (i.projection_type == "INCLUDE" ? length(i.non_key_attributes) > 0 : length(i.non_key_attributes) == 0)
    ]), false)])
    error_message = "Projection must be ALL, KEYS_ONLY, or INCLUDE; only INCLUDE accepts and requires non-key attributes."
  }
  validation {
    condition = alltrue([for t in var.tables : try(alltrue([for i in t.global_secondary_index :
      length(i.key_schema) == 0 ? length(trimspace(coalesce(i.hash_key, " "))) > 0 :
      (i.hash_key == null && i.range_key == null &&
        length([for k in i.key_schema : k if k.key_type == "HASH"]) >= 1 &&
        length([for k in i.key_schema : k if k.key_type == "HASH"]) <= 4 &&
        length([for k in i.key_schema : k if k.key_type == "RANGE"]) <= 4 &&
        alltrue([for k in i.key_schema : contains(["HASH", "RANGE"], k.key_type)]) &&
      length(distinct([for k in i.key_schema : k.attribute_name])) == length(i.key_schema))
    ]), false)])
    error_message = "GSI keys require a legacy hash_key or ordered key_schema (1..4 HASH, 0..4 RANGE, distinct attributes), never both."
  }
  validation {
    condition     = alltrue([for t in var.tables : try(length(compact([t.restore_backup_arn, t.restore_source_name, t.restore_source_table_arn])) <= 1, false)])
    error_message = "Select at most one backup ARN, source name, or source table ARN."
  }
  validation {
    condition     = alltrue([for t in var.tables : try(t.import_table == null ? true : length(compact([t.restore_backup_arn, t.restore_source_name, t.restore_source_table_arn])) == 0, false)])
    error_message = "import_table conflicts with every restore source."
  }
  validation {
    condition     = alltrue([for t in var.tables : try(t.restore_date_time == null ? true : (can(formatdate("YYYY", t.restore_date_time)) && can(regex("Z$", t.restore_date_time)) && t.restore_to_latest_time != true), false)])
    error_message = "restore_date_time must be UTC RFC3339 and cannot accompany restore_to_latest_time=true."
  }
  validation {
    condition     = alltrue([for t in var.tables : try(t.restore_date_time == null && t.restore_to_latest_time == null ? true : length(compact([t.restore_source_name, t.restore_source_table_arn])) == 1, false)])
    error_message = "PITR restore time/latest options require a source name or source table ARN, not a backup."
  }
  validation {
    condition     = alltrue([for t in var.tables : try(t.import_table == null ? true : (contains(["CSV", "DYNAMODB_JSON", "ION"], t.import_table.input_format) && (t.import_table.input_compression_type == null ? true : contains(["GZIP", "ZSTD", "NONE"], t.import_table.input_compression_type)) && (t.import_table.input_format_options == null ? true : t.import_table.input_format == "CSV")), false)])
    error_message = "Import format must be CSV/DYNAMODB_JSON/ION, compression GZIP/ZSTD/NONE; options apply only to CSV."
  }
  validation {
    condition = alltrue([for t in var.tables : try(
      length(distinct([for r in t.replica : r.region_name])) == length(t.replica) &&
      alltrue([for r in t.replica : r.region_name != t.region && contains(["EVENTUAL", "STRONG"], r.consistency_mode)]) &&
      length(distinct([for r in t.replica : r.consistency_mode])) <= 1 &&
      (t.global_table_witness == null ? true : (t.global_table_witness.region_name != t.region && !contains([for r in t.replica : r.region_name], t.global_table_witness.region_name))),
    false)])
    error_message = "Replica/witness regions must be distinct and differ from an explicit source region; consistency must agree and be EVENTUAL/STRONG."
  }
  validation {
    condition = alltrue([for t in var.tables : try(
      contains([for r in t.replica : r.consistency_mode], "STRONG") ?
      ((t.global_table_witness == null ? length(t.replica) == 2 : length(t.replica) == 1) && !try(t.ttl.enabled, false) && length(t.local_secondary_index) == 0) :
      (t.global_table_witness == null && (length(t.replica) == 0 || t.stream_enabled)),
    false)])
    error_message = "STRONG requires two replicas or one plus witness, with no enabled TTL or LSIs. EVENTUAL replicas require streams and forbid a witness."
  }
}
