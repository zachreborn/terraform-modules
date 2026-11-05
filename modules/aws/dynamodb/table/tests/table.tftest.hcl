mock_provider "aws" {
  mock_resource "aws_dynamodb_table" {
    defaults = {
      id           = "physical-webhook"
      arn          = "arn:aws:dynamodb:us-east-1:123456789012:table/physical-webhook"
      stream_arn   = "arn:aws:dynamodb:us-east-1:123456789012:table/physical-webhook/stream/2026-01-01T00:00:00.000"
      stream_label = "2026-01-01T00:00:00.000"
      tags_all     = { Name = "physical-webhook", Team = "platform" }
    }
  }
}

mock_provider "aws" {
  alias = "region_fallback"
  mock_resource "aws_dynamodb_table" {
    defaults = {
      id       = "physical-webhook"
      arn      = "arn:aws:dynamodb:us-east-1:123456789012:table/physical-webhook"
      tags_all = { Name = "physical-webhook", Team = "platform" }
      region   = "us-east-1"
    }
  }
}

run "explicit_null_safe_defaults" {
  command   = apply
  providers = { aws = aws.region_fallback }
  variables {
    tables = {
      webhook = {
        name                   = "physical-webhook", hash_key = "pk", attribute = [{ name = "pk", type = "S" }]
        point_in_time_recovery = null
        server_side_encryption = null
        region                 = null
        ttl                    = null
      }
    }
  }
  assert {
    condition     = aws_dynamodb_table.this["webhook"].region == "us-east-1" && aws_dynamodb_table.this["webhook"].point_in_time_recovery[0].enabled && aws_dynamodb_table.this["webhook"].server_side_encryption[0].enabled && length(aws_dynamodb_table.this["webhook"].ttl) == 0
    error_message = "Null optional security objects must retain secure defaults, provider-region fallback and omitted TTL."
  }
}

run "null_map_selects_empty_default" {
  command = plan
  variables { tables = null }
  assert {
    condition     = output.tables == tomap({}) && length(aws_dynamodb_table.this) == 0
    error_message = "The non-nullable table-map default must select an empty map for explicit null."
  }
}

mock_provider "aws" {
  alias = "replica_without_stream"
  mock_resource "aws_dynamodb_table" {
    defaults = {
      id       = "physical-webhook"
      arn      = "arn:aws:dynamodb:us-east-1:123456789012:table/physical-webhook"
      tags_all = { Name = "physical-webhook", Team = "platform" }
      replica = {
        arn          = "arn:aws:dynamodb:us-west-2:123456789012:table/physical-webhook"
        stream_arn   = ""
        stream_label = ""
      }
    }
  }
}

run "strong_replica_null_stream_outputs" {
  command   = apply
  providers = { aws = aws.replica_without_stream }
  variables {
    tables = {
      webhook = {
        name                 = "physical-webhook", hash_key = "pk", attribute = [{ name = "pk", type = "S" }]
        replica              = [{ region_name = "us-west-2", consistency_mode = "STRONG" }]
        global_table_witness = { region_name = "us-east-2" }
      }
    }
  }
  assert {
    condition = output.replicas == tomap({ webhook = tomap({ "us-west-2" = {
      arn          = "arn:aws:dynamodb:us-west-2:123456789012:table/physical-webhook"
      stream_arn   = tostring(null)
      stream_label = tostring(null)
    } }) }) && output.stream_arns["webhook"] == null && output.stream_labels["webhook"] == null && output.tables["webhook"].replicas == output.replicas["webhook"]
    error_message = "Streamless replica fields must normalize empty provider values to typed null, including aggregate output."
  }
}

run "lsi_all_and_include_preserve_list_order" {
  command = plan
  variables {
    tables = {
      webhook = {
        name      = "physical-webhook", hash_key = "pk", range_key = "sk"
        attribute = [{ name = "pk", type = "S" }, { name = "sk", type = "S" }]
        local_secondary_index = [
          { name = "all-index", range_key = "sk", projection_type = "ALL" },
          { name = "include-index", range_key = "sk", projection_type = "INCLUDE", non_key_attributes = ["z", "a"] }
        ]
      }
    }
  }
  assert {
    condition     = one([for i in aws_dynamodb_table.this["webhook"].local_secondary_index : i if i.name == "all-index"]).projection_type == "ALL" && one([for i in aws_dynamodb_table.this["webhook"].local_secondary_index : i if i.name == "include-index"]).non_key_attributes == tolist(["z", "a"])
    error_message = "LSI ALL and INCLUDE branches must preserve the ordered non-key attribute list."
  }
}

run "index_name_inclusive_boundaries" {
  command = plan
  variables {
    tables = {
      webhook = {
        name = "physical-webhook", hash_key = "pk", attribute = [{ name = "pk", type = "S" }]
        global_secondary_index = [
          { name = "a.-", hash_key = "pk", projection_type = "ALL" },
          { name = join("", [for i in range(255) : "a"]), hash_key = "pk", projection_type = "KEYS_ONLY" }
        ]
      }
    }
  }
  assert {
    condition     = toset([for i in aws_dynamodb_table.this["webhook"].global_secondary_index : length(i.name)]) == toset([3, 255])
    error_message = "Index-name minimum/maximum lengths and valid punctuation must be accepted."
  }
}

run "restore_all_sources_without_creation_keys" {
  command = plan
  variables {
    tables = {
      backup = {
        name               = "restored-backup"
        restore_backup_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source/backup/0123456789"
      }
      named = {
        name                   = "restored-name"
        restore_source_name    = "source"
        restore_date_time      = "2026-01-01T00:00:00Z"
        restore_to_latest_time = false
      }
      arn = {
        name                     = "restored-arn"
        restore_source_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source"
        restore_to_latest_time   = true
        billing_mode             = "PROVISIONED"
      }
    }
  }
  assert {
    condition     = aws_dynamodb_table.this["backup"].restore_backup_arn == "arn:aws:dynamodb:us-east-1:123456789012:table/source/backup/0123456789" && aws_dynamodb_table.this["named"].restore_source_name == "source" && aws_dynamodb_table.this["named"].restore_date_time == "2026-01-01T00:00:00Z" && !aws_dynamodb_table.this["named"].restore_to_latest_time && aws_dynamodb_table.this["arn"].restore_source_table_arn == "arn:aws:dynamodb:us-east-1:123456789012:table/source" && aws_dynamodb_table.this["arn"].restore_to_latest_time
    error_message = "All three mutually exclusive restore selectors and PITR options must be wired unchanged."
  }
  assert {
    condition     = alltrue([for t in var.tables : try(t.hash_key, null) == null && length(try(t.attribute, [])) == 0 && try(t.read_capacity, null) == null && try(t.write_capacity, null) == null])
    error_message = "Restores must allow omission of creation keys and capacities."
  }
}

run "csv_import_all_nested_options" {
  command = plan
  variables {
    tables = {
      webhook = {
        name      = "physical-webhook"
        hash_key  = "pk"
        attribute = [{ name = "pk", type = "S" }]
        import_table = {
          input_format           = "CSV"
          input_compression_type = "GZIP"
          s3_bucket_source       = { bucket = "fake-import", bucket_owner = "123456789012", key_prefix = "data/" }
          input_format_options   = { csv = { delimiter = "|", header_list = ["pk", "value"] } }
        }
      }
    }
  }
  assert {
    condition     = aws_dynamodb_table.this["webhook"].import_table[0].input_format == "CSV" && aws_dynamodb_table.this["webhook"].import_table[0].input_compression_type == "GZIP" && aws_dynamodb_table.this["webhook"].import_table[0].s3_bucket_source[0].bucket == "fake-import" && aws_dynamodb_table.this["webhook"].import_table[0].s3_bucket_source[0].bucket_owner == "123456789012" && aws_dynamodb_table.this["webhook"].import_table[0].s3_bucket_source[0].key_prefix == "data/" && aws_dynamodb_table.this["webhook"].import_table[0].input_format_options[0].csv[0].delimiter == "|" && aws_dynamodb_table.this["webhook"].import_table[0].input_format_options[0].csv[0].header_list == toset(["pk", "value"])
    error_message = "CSV import source, owner, prefix, format, compression, delimiter and headers must all reach the resource."
  }
}

run "import_formats_and_optional_csv_branches" {
  command = plan
  variables {
    tables = {
      json = {
        name         = "json-import", hash_key = "pk", attribute = [{ name = "pk", type = "S" }]
        import_table = { input_format = "DYNAMODB_JSON", input_compression_type = "ZSTD", s3_bucket_source = { bucket = "fake-import" } }
      }
      ion = {
        name         = "ion-import", hash_key = "pk", attribute = [{ name = "pk", type = "S" }]
        import_table = { input_format = "ION", input_compression_type = "NONE", s3_bucket_source = { bucket = "fake-import" } }
      }
      csv = {
        name         = "csv-import", hash_key = "pk", attribute = [{ name = "pk", type = "S" }]
        import_table = { input_format = "CSV", s3_bucket_source = { bucket = "fake-import" } }
      }
      options = {
        name         = "csv-options", hash_key = "pk", attribute = [{ name = "pk", type = "S" }]
        import_table = { input_format = "CSV", s3_bucket_source = { bucket = "fake-import" }, input_format_options = {} }
      }
      defaults = {
        name         = "csv-defaults", hash_key = "pk", attribute = [{ name = "pk", type = "S" }]
        import_table = { input_format = "CSV", s3_bucket_source = { bucket = "fake-import" }, input_format_options = { csv = {} } }
      }
    }
  }
  assert {
    condition     = aws_dynamodb_table.this["json"].import_table[0].input_format == "DYNAMODB_JSON" && aws_dynamodb_table.this["json"].import_table[0].input_compression_type == "ZSTD" && length(aws_dynamodb_table.this["json"].import_table[0].input_format_options) == 0 && aws_dynamodb_table.this["ion"].import_table[0].input_format == "ION" && aws_dynamodb_table.this["ion"].import_table[0].input_compression_type == "NONE" && length(aws_dynamodb_table.this["csv"].import_table[0].input_format_options) == 0 && length(aws_dynamodb_table.this["options"].import_table[0].input_format_options[0].csv) == 0 && length(aws_dynamodb_table.this["defaults"].import_table[0].input_format_options[0].csv) == 1
    error_message = "JSON/ION and each optional CSV block branch must preserve configuration without invented options."
  }
}

run "ordered_four_hash_four_range_boundary" {
  command = plan
  variables {
    tables = { webhook = {
      name      = "physical-webhook", hash_key = "pk"
      attribute = concat([{ name = "pk", type = "S" }], [for i in range(8) : { name = "key${i}", type = "S" }])
      global_secondary_index = [{
        name       = "max", projection_type = "KEYS_ONLY"
        key_schema = [for i in range(8) : { attribute_name = "key${i}", key_type = i < 4 ? "HASH" : "RANGE" }]
      }]
    } }
  }
  assert {
    condition     = one(aws_dynamodb_table.this["webhook"].global_secondary_index).key_schema == tolist([for i in range(8) : { attribute_name = "key${i}", key_type = i < 4 ? "HASH" : "RANGE" }])
    error_message = "The maximum ordered schema must preserve all four HASH and four RANGE entries in order."
  }
}

run "all_stream_views" {
  command = plan
  variables {
    tables = { for v in ["KEYS_ONLY", "NEW_IMAGE", "OLD_IMAGE", "NEW_AND_OLD_IMAGES"] : v => {
      name = "table-${v}", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], stream_enabled = true, stream_view_type = v
    } }
  }
  assert {
    condition     = alltrue([for k, t in aws_dynamodb_table.this : t.stream_enabled && t.stream_view_type == k])
    error_message = "Every documented stream view must be accepted and forwarded."
  }
}

run "nullable_options_and_single_sided_throughput" {
  command = plan
  variables {
    tables = {
      webhook = {
        name                 = "physical-webhook", hash_key = "pk", attribute = [{ name = "pk", type = "S" }]
        region               = null, ttl = {}, timeouts = null, import_table = null, global_table_witness = null
        on_demand_throughput = { max_write_request_units = 1 }
        warm_throughput      = { read_units_per_second = 12000 }
        global_secondary_index = [{
          name                 = "idx", projection_type = "ALL", key_schema = [{ attribute_name = "pk", key_type = "HASH" }]
          warm_throughput      = { write_units_per_second = 4000 }
          on_demand_throughput = { max_write_request_units = -1 }
        }]
      }
    }
  }
  assert {
    condition     = !aws_dynamodb_table.this["webhook"].ttl[0].enabled && length(aws_dynamodb_table.this["webhook"].import_table) == 0 && aws_dynamodb_table.this["webhook"].timeouts == null && aws_dynamodb_table.this["webhook"].on_demand_throughput[0].max_write_request_units == 1 && aws_dynamodb_table.this["webhook"].warm_throughput[0].read_units_per_second == 12000 && one(aws_dynamodb_table.this["webhook"].global_secondary_index).warm_throughput[0].write_units_per_second == 4000 && one(aws_dynamodb_table.this["webhook"].global_secondary_index).on_demand_throughput[0].max_write_request_units == -1
    error_message = "Null options must omit blocks, disabled TTL may omit its name, and throughput fields are independently optional."
  }
}

mock_provider "aws" {
  alias = "replicated"
  mock_resource "aws_dynamodb_table" {
    defaults = {
      id           = "physical-webhook"
      arn          = "arn:aws:dynamodb:us-east-1:123456789012:table/physical-webhook"
      stream_arn   = "arn:aws:dynamodb:us-east-1:123456789012:table/physical-webhook/stream/2026-01-01T00:00:00.000"
      stream_label = "2026-01-01T00:00:00.000"
      tags_all     = { Name = "physical-webhook", Team = "platform" }
      replica = {
        arn          = "arn:aws:dynamodb:us-west-2:123456789012:table/physical-webhook"
        stream_arn   = "arn:aws:dynamodb:us-west-2:123456789012:table/physical-webhook/stream/2026-01-01T00:00:00.000"
        stream_label = "2026-01-01T00:00:00.000"
      }
    }
  }
}

variables {
  tags = { Team = "platform" }
  tables = {
    webhook = {
      name      = "physical-webhook"
      hash_key  = "pk"
      attribute = [{ name = "pk", type = "S" }]
      ttl       = { enabled = true, attribute_name = "ttl" }
    }
  }
}

run "required_issue_baseline" {
  command = plan
  assert {
    condition     = aws_dynamodb_table.this["webhook"].name == "physical-webhook" && aws_dynamodb_table.this["webhook"].billing_mode == "PAY_PER_REQUEST" && aws_dynamodb_table.this["webhook"].hash_key == "pk" && aws_dynamodb_table.this["webhook"].attribute == toset([{ name = "pk", type = "S" }])
    error_message = "The physical name, billing and key schema must match the adopted table."
  }
  assert {
    condition     = aws_dynamodb_table.this["webhook"].ttl[0].enabled && aws_dynamodb_table.this["webhook"].ttl[0].attribute_name == "ttl" && aws_dynamodb_table.this["webhook"].point_in_time_recovery[0].enabled && aws_dynamodb_table.this["webhook"].server_side_encryption[0].enabled && aws_dynamodb_table.this["webhook"].deletion_protection_enabled
    error_message = "TTL, PITR, encryption and deletion protection must be enabled."
  }
  assert {
    condition     = var.tables["webhook"].server_side_encryption.kms_key_arn == null && length(aws_dynamodb_table.this) == 1 && aws_dynamodb_table.this["webhook"].tags == tomap({ Name = "physical-webhook", Team = "platform" })
    error_message = "Use AWS-managed encryption with no customer key resource and merge Name tags."
  }
}

run "exact_outputs_streams_disabled" {
  command = apply
  assert {
    condition     = output.table_names == tomap({ webhook = "physical-webhook" }) && output.table_ids == tomap({ webhook = "physical-webhook" }) && output.table_arns == tomap({ webhook = "arn:aws:dynamodb:us-east-1:123456789012:table/physical-webhook" })
    error_message = "Names, IDs and ARNs must retain the logical key and provider identifiers."
  }
  assert {
    condition     = output.stream_arns == tomap({ webhook = tostring(null) }) && output.stream_labels == tomap({ webhook = tostring(null) }) && output.tags_all == tomap({ webhook = tomap({ Name = "physical-webhook", Team = "platform" }) }) && output.replicas == tomap({ webhook = tomap({}) })
    error_message = "Disabled stream outputs must be null; tags and replica outputs must be exact."
  }
  assert {
    condition = output.tables == tomap({ webhook = {
      name         = "physical-webhook"
      id           = "physical-webhook"
      arn          = "arn:aws:dynamodb:us-east-1:123456789012:table/physical-webhook"
      stream_arn   = tostring(null)
      stream_label = tostring(null)
      tags_all     = tomap({ Name = "physical-webhook", Team = "platform" })
      replicas     = tomap({})
    } })
    error_message = "The aggregate must contain the same exact identity and metadata."
  }
}

run "empty_map" {
  command = plan
  variables {
    tables = {}
  }
  assert {
    condition     = output.tables == tomap({}) && output.table_names == tomap({}) && output.table_ids == tomap({}) && output.table_arns == tomap({}) && output.stream_arns == tomap({}) && output.stream_labels == tomap({}) && output.tags_all == tomap({}) && output.replicas == tomap({})
    error_message = "Empty input must return empty maps and create no tables."
  }
}

run "two_tables_and_tag_precedence" {
  command = plan
  variables {
    tags = { Name = "shared", Team = "platform" }
    tables = {
      first = {
        name      = "physical-first"
        hash_key  = "pk"
        attribute = [{ name = "pk", type = "S" }]
        tags      = { Name = "per-table", Owner = "test" }
      }
      second = {
        name      = "physical-second"
        hash_key  = "pk"
        attribute = [{ name = "pk", type = "B" }]
      }
    }
  }
  assert {
    condition     = output.table_names == tomap({ first = "physical-first", second = "physical-second" }) && aws_dynamodb_table.this["first"].tags == tomap({ Name = "per-table", Team = "platform", Owner = "test" }) && aws_dynamodb_table.this["second"].tags == tomap({ Name = "shared", Team = "platform" })
    error_message = "Stable keys and Name/shared/table tag precedence must be preserved."
  }
}

run "advanced_provisioned_indexes" {
  command = plan
  variables {
    tables = {
      webhook = {
        name           = "physical-webhook"
        region         = "us-east-1"
        hash_key       = "pk"
        range_key      = "sk"
        billing_mode   = "PROVISIONED"
        read_capacity  = 1
        write_capacity = 2
        table_class    = "STANDARD_INFREQUENT_ACCESS"
        attribute = [
          { name = "pk", type = "S" }, { name = "sk", type = "N" }, { name = "other", type = "B" }
        ]
        global_secondary_index = [{
          name               = "legacy-index"
          hash_key           = "other"
          range_key          = "sk"
          projection_type    = "INCLUDE"
          non_key_attributes = ["extra"]
          read_capacity      = 3
          write_capacity     = 4
          warm_throughput    = { read_units_per_second = 12000, write_units_per_second = 4000 }
        }]
        local_secondary_index       = [{ name = "local-index", range_key = "other", projection_type = "KEYS_ONLY" }]
        ttl                         = { enabled = false, attribute_name = "old-ttl" }
        point_in_time_recovery      = { enabled = false, recovery_period_in_days = 1 }
        server_side_encryption      = { enabled = false }
        warm_throughput             = { read_units_per_second = 12000, write_units_per_second = 4000 }
        deletion_protection_enabled = false
        timeouts                    = { create = "60m", update = "45m", delete = "30m" }
      }
    }
  }
  assert {
    condition     = aws_dynamodb_table.this["webhook"].region == "us-east-1" && aws_dynamodb_table.this["webhook"].read_capacity == 1 && aws_dynamodb_table.this["webhook"].write_capacity == 2 && aws_dynamodb_table.this["webhook"].table_class == "STANDARD_INFREQUENT_ACCESS" && !aws_dynamodb_table.this["webhook"].deletion_protection_enabled
    error_message = "Provisioned units, explicit region, class and deletion override must be forwarded."
  }
  assert {
    condition     = one(aws_dynamodb_table.this["webhook"].global_secondary_index).read_capacity == 3 && one(aws_dynamodb_table.this["webhook"].global_secondary_index).write_capacity == 4 && one(aws_dynamodb_table.this["webhook"].global_secondary_index).non_key_attributes == toset(["extra"]) && one(aws_dynamodb_table.this["webhook"].local_secondary_index).range_key == "other"
    error_message = "GSI and LSI fields must reach the real resource."
  }
  assert {
    condition     = !aws_dynamodb_table.this["webhook"].ttl[0].enabled && aws_dynamodb_table.this["webhook"].ttl[0].attribute_name == "old-ttl" && !aws_dynamodb_table.this["webhook"].point_in_time_recovery[0].enabled && !aws_dynamodb_table.this["webhook"].server_side_encryption[0].enabled && aws_dynamodb_table.this["webhook"].warm_throughput[0].read_units_per_second == 12000 && one(aws_dynamodb_table.this["webhook"].global_secondary_index).warm_throughput[0].write_units_per_second == 4000 && aws_dynamodb_table.this["webhook"].timeouts.create == "60m" && aws_dynamodb_table.this["webhook"].timeouts.update == "45m" && aws_dynamodb_table.this["webhook"].timeouts.delete == "30m"
    error_message = "Disabled TTL retains its name, security overrides, warm capacity and timeouts must be wired."
  }
}

run "ordered_indexes_and_on_demand_boundaries" {
  command = plan
  variables {
    tables = {
      webhook = {
        name      = "physical-webhook"
        hash_key  = "pk"
        attribute = [{ name = "pk", type = "S" }, { name = "sk", type = "S" }]
        global_secondary_index = [{
          name                 = "ordered-index"
          key_schema           = [{ attribute_name = "sk", key_type = "HASH" }, { attribute_name = "pk", key_type = "RANGE" }]
          projection_type      = "ALL"
          on_demand_throughput = { max_read_request_units = -1, max_write_request_units = 1 }
        }]
        on_demand_throughput   = { max_read_request_units = 1, max_write_request_units = -1 }
        point_in_time_recovery = { recovery_period_in_days = 35 }
        server_side_encryption = { kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000001" }
      }
    }
  }
  assert {
    condition     = one(aws_dynamodb_table.this["webhook"].global_secondary_index).key_schema == tolist([{ attribute_name = "sk", key_type = "HASH" }, { attribute_name = "pk", key_type = "RANGE" }]) && aws_dynamodb_table.this["webhook"].on_demand_throughput[0].max_read_request_units == 1 && one(aws_dynamodb_table.this["webhook"].global_secondary_index).on_demand_throughput[0].max_read_request_units == -1 && aws_dynamodb_table.this["webhook"].point_in_time_recovery[0].recovery_period_in_days == 35
    error_message = "Ordered key schemas and inclusive on-demand/recovery boundaries must be preserved."
  }
  assert {
    condition     = aws_dynamodb_table.this["webhook"].server_side_encryption[0].kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-0000-0000-000000000001"
    error_message = "An external customer-managed encryption key must be passed unchanged."
  }
}

run "eventual_replica_exact_outputs" {
  command   = apply
  providers = { aws = aws.replicated }
  variables {
    tables = {
      webhook = {
        name             = "physical-webhook"
        hash_key         = "pk"
        attribute        = [{ name = "pk", type = "S" }]
        stream_enabled   = true
        stream_view_type = "NEW_AND_OLD_IMAGES"
        replica          = [{ region_name = "us-west-2" }]
      }
    }
  }
  assert {
    condition     = output.stream_arns["webhook"] == "arn:aws:dynamodb:us-east-1:123456789012:table/physical-webhook/stream/2026-01-01T00:00:00.000" && output.stream_labels["webhook"] == "2026-01-01T00:00:00.000"
    error_message = "Enabled stream outputs must equal computed provider metadata."
  }
  assert {
    condition = output.replicas == tomap({ webhook = tomap({ "us-west-2" = {
      arn          = "arn:aws:dynamodb:us-west-2:123456789012:table/physical-webhook"
      stream_arn   = "arn:aws:dynamodb:us-west-2:123456789012:table/physical-webhook/stream/2026-01-01T00:00:00.000"
      stream_label = "2026-01-01T00:00:00.000"
    } }) })
    error_message = "Replica output must be keyed by table then region and contain exact computed attributes."
  }
  assert {
    condition     = output.tables["webhook"].replicas == output.replicas["webhook"] && output.tables["webhook"].stream_arn == output.stream_arns["webhook"] && output.tables["webhook"].stream_label == output.stream_labels["webhook"] && one(aws_dynamodb_table.this["webhook"].replica).point_in_time_recovery && one(aws_dynamodb_table.this["webhook"].replica).deletion_protection_enabled && one(aws_dynamodb_table.this["webhook"].replica).propagate_tags
    error_message = "Aggregate output and secure replica defaults must match."
  }
}

run "strong_two_replicas_without_streams" {
  command = plan
  variables {
    tables = {
      webhook = {
        name      = "physical-webhook"
        hash_key  = "pk"
        attribute = [{ name = "pk", type = "S" }]
        replica   = [{ region_name = "us-west-2", consistency_mode = "STRONG" }, { region_name = "us-east-2", consistency_mode = "STRONG" }]
      }
    }
  }
  assert {
    condition     = !aws_dynamodb_table.this["webhook"].stream_enabled && length(aws_dynamodb_table.this["webhook"].replica) == 2
    error_message = "STRONG must not incorrectly require streams."
  }
}

run "strong_replica_and_witness" {
  command = plan
  variables {
    tables = {
      webhook = {
        name                 = "physical-webhook"
        hash_key             = "pk"
        attribute            = [{ name = "pk", type = "S" }]
        replica              = [{ region_name = "us-west-2", consistency_mode = "STRONG", propagate_tags = false, point_in_time_recovery = false, deletion_protection_enabled = false, kms_key_arn = "arn:aws:kms:us-west-2:123456789012:key/00000000-0000-0000-0000-000000000001" }]
        global_table_witness = { region_name = "us-east-2" }
      }
    }
  }
  assert {
    condition     = aws_dynamodb_table.this["webhook"].global_table_witness[0].region_name == "us-east-2" && one(aws_dynamodb_table.this["webhook"].replica).consistency_mode == "STRONG" && !one(aws_dynamodb_table.this["webhook"].replica).propagate_tags && !one(aws_dynamodb_table.this["webhook"].replica).point_in_time_recovery && !one(aws_dynamodb_table.this["webhook"].replica).deletion_protection_enabled && one(aws_dynamodb_table.this["webhook"].replica).kms_key_arn == "arn:aws:kms:us-west-2:123456789012:key/00000000-0000-0000-0000-000000000001"
    error_message = "Witness and every replica override must be wired."
  }
}
