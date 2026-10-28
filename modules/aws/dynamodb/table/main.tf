###########################
# Requirements
###########################
terraform {
  # Optional object attribute defaults require Terraform 1.3.
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # restore_backup_arn was introduced in 6.38.0.
      version = ">= 6.38.0"
    }
  }
}

###########################
# Tables
###########################
resource "aws_dynamodb_table" "this" {
  for_each = var.tables

  name                        = each.value.name
  region                      = each.value.region
  billing_mode                = each.value.billing_mode
  hash_key                    = each.value.hash_key
  range_key                   = each.value.range_key
  read_capacity               = each.value.read_capacity
  write_capacity              = each.value.write_capacity
  deletion_protection_enabled = each.value.deletion_protection_enabled
  table_class                 = each.value.table_class
  stream_enabled              = each.value.stream_enabled
  stream_view_type            = each.value.stream_view_type
  restore_backup_arn          = each.value.restore_backup_arn
  restore_source_name         = each.value.restore_source_name
  restore_source_table_arn    = each.value.restore_source_table_arn
  restore_date_time           = each.value.restore_date_time
  restore_to_latest_time      = each.value.restore_to_latest_time
  tags                        = merge({ Name = each.value.name }, var.tags, each.value.tags)

  dynamic "attribute" {
    for_each = each.value.attribute
    content {
      name = attribute.value.name
      type = attribute.value.type
    }
  }
  dynamic "ttl" {
    for_each = each.value.ttl == null ? [] : [each.value.ttl]
    content {
      attribute_name = ttl.value.attribute_name
      enabled        = ttl.value.enabled
    }
  }
  dynamic "point_in_time_recovery" {
    for_each = each.value.point_in_time_recovery == null ? [] : [each.value.point_in_time_recovery]
    content {
      enabled                 = point_in_time_recovery.value.enabled
      recovery_period_in_days = point_in_time_recovery.value.recovery_period_in_days
    }
  }
  dynamic "server_side_encryption" {
    for_each = each.value.server_side_encryption == null ? [] : [each.value.server_side_encryption]
    content {
      enabled     = server_side_encryption.value.enabled
      kms_key_arn = server_side_encryption.value.kms_key_arn
    }
  }
  dynamic "on_demand_throughput" {
    for_each = each.value.on_demand_throughput == null ? [] : [each.value.on_demand_throughput]
    content {
      max_read_request_units  = on_demand_throughput.value.max_read_request_units
      max_write_request_units = on_demand_throughput.value.max_write_request_units
    }
  }
  dynamic "warm_throughput" {
    for_each = each.value.warm_throughput == null ? [] : [each.value.warm_throughput]
    content {
      read_units_per_second  = warm_throughput.value.read_units_per_second
      write_units_per_second = warm_throughput.value.write_units_per_second
    }
  }
  dynamic "global_secondary_index" {
    for_each = each.value.global_secondary_index
    content {
      name               = global_secondary_index.value.name
      projection_type    = global_secondary_index.value.projection_type
      hash_key           = global_secondary_index.value.hash_key
      range_key          = global_secondary_index.value.range_key
      non_key_attributes = global_secondary_index.value.non_key_attributes
      read_capacity      = global_secondary_index.value.read_capacity
      write_capacity     = global_secondary_index.value.write_capacity
      dynamic "key_schema" {
        for_each = global_secondary_index.value.key_schema
        content {
          attribute_name = key_schema.value.attribute_name
          key_type       = key_schema.value.key_type
        }
      }
      dynamic "on_demand_throughput" {
        for_each = global_secondary_index.value.on_demand_throughput == null ? [] : [global_secondary_index.value.on_demand_throughput]
        content {
          max_read_request_units  = on_demand_throughput.value.max_read_request_units
          max_write_request_units = on_demand_throughput.value.max_write_request_units
        }
      }
      dynamic "warm_throughput" {
        for_each = global_secondary_index.value.warm_throughput == null ? [] : [global_secondary_index.value.warm_throughput]
        content {
          read_units_per_second  = warm_throughput.value.read_units_per_second
          write_units_per_second = warm_throughput.value.write_units_per_second
        }
      }
    }
  }
  dynamic "local_secondary_index" {
    for_each = each.value.local_secondary_index
    content {
      name               = local_secondary_index.value.name
      range_key          = local_secondary_index.value.range_key
      projection_type    = local_secondary_index.value.projection_type
      non_key_attributes = local_secondary_index.value.non_key_attributes
    }
  }
  dynamic "replica" {
    for_each = each.value.replica
    content {
      region_name                 = replica.value.region_name
      kms_key_arn                 = replica.value.kms_key_arn
      point_in_time_recovery      = replica.value.point_in_time_recovery
      propagate_tags              = replica.value.propagate_tags
      deletion_protection_enabled = replica.value.deletion_protection_enabled
      consistency_mode            = replica.value.consistency_mode
    }
  }
  dynamic "global_table_witness" {
    for_each = each.value.global_table_witness == null ? [] : [each.value.global_table_witness]
    content {
      region_name = global_table_witness.value.region_name
    }
  }
  dynamic "import_table" {
    for_each = each.value.import_table == null ? [] : [each.value.import_table]
    content {
      input_format           = import_table.value.input_format
      input_compression_type = import_table.value.input_compression_type
      s3_bucket_source {
        bucket       = import_table.value.s3_bucket_source.bucket
        bucket_owner = import_table.value.s3_bucket_source.bucket_owner
        key_prefix   = import_table.value.s3_bucket_source.key_prefix
      }
      dynamic "input_format_options" {
        for_each = import_table.value.input_format_options == null ? [] : [import_table.value.input_format_options]
        content {
          dynamic "csv" {
            for_each = input_format_options.value.csv == null ? [] : [input_format_options.value.csv]
            content {
              delimiter   = csv.value.delimiter
              header_list = csv.value.header_list
            }
          }
        }
      }
    }
  }
  dynamic "timeouts" {
    for_each = each.value.timeouts == null ? [] : [each.value.timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
