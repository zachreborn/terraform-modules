mock_provider "aws" {}

run "gsi_nonpositive_read" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], billing_mode = "PROVISIONED", read_capacity = 1, write_capacity = 1, global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", read_capacity = 0, write_capacity = 1 }] } } }
  expect_failures = [var.tables]
}
run "gsi_nonpositive_write" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], billing_mode = "PROVISIONED", read_capacity = 1, write_capacity = 1, global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", read_capacity = 1, write_capacity = 0 }] } } }
  expect_failures = [var.tables]
}
run "gsi_fractional_read" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], billing_mode = "PROVISIONED", read_capacity = 1, write_capacity = 1, global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", read_capacity = 1.5, write_capacity = 1 }] } } }
  expect_failures = [var.tables]
}
run "gsi_fractional_write" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], billing_mode = "PROVISIONED", read_capacity = 1, write_capacity = 1, global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", read_capacity = 1, write_capacity = 1.5 }] } } }
  expect_failures = [var.tables]
}
run "gsi_on_demand_read_capacity" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", read_capacity = 1 }] } } }
  expect_failures = [var.tables]
}
run "gsi_on_demand_write_capacity" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", write_capacity = 1 }] } } }
  expect_failures = [var.tables]
}
run "gsi_provisioned_cap" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], billing_mode = "PROVISIONED", read_capacity = 1, write_capacity = 1, global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", read_capacity = 1, write_capacity = 1, on_demand_throughput = { max_read_request_units = 1 } }] } } }
  expect_failures = [var.tables]
}
run "gsi_zero_read_cap" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", on_demand_throughput = { max_read_request_units = 0 } }] } } }
  expect_failures = [var.tables]
}
run "gsi_negative_read_cap" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", on_demand_throughput = { max_read_request_units = -2 } }] } } }
  expect_failures = [var.tables]
}
run "gsi_fractional_read_cap" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", on_demand_throughput = { max_read_request_units = 1.5 } }] } } }
  expect_failures = [var.tables]
}
run "gsi_zero_write_cap" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", on_demand_throughput = { max_write_request_units = 0 } }] } } }
  expect_failures = [var.tables]
}
run "gsi_negative_write_cap" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", on_demand_throughput = { max_write_request_units = -2 } }] } } }
  expect_failures = [var.tables]
}
run "gsi_fractional_write_cap" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", on_demand_throughput = { max_write_request_units = 1.5 } }] } } }
  expect_failures = [var.tables]
}
run "gsi_warm_reads_below_minimum" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", warm_throughput = { read_units_per_second = 11999 } }] } } }
  expect_failures = [var.tables]
}
run "gsi_warm_reads_fractional" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", warm_throughput = { read_units_per_second = 12000.5 } }] } } }
  expect_failures = [var.tables]
}
run "gsi_warm_writes_below_minimum" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", warm_throughput = { write_units_per_second = 3999 } }] } } }
  expect_failures = [var.tables]
}
run "gsi_warm_writes_fractional" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", warm_throughput = { write_units_per_second = 4000.5 } }] } } }
  expect_failures = [var.tables]
}
run "missing_lsi_attribute" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", range_key = "sk", attribute = [{ name = "pk", type = "S" }, { name = "sk", type = "S" }], local_secondary_index = [{ name = "local", range_key = "missing", projection_type = "ALL" }] } } }
  expect_failures = [var.tables]
}
run "duplicate_global_local_names" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", range_key = "sk", attribute = [{ name = "pk", type = "S" }, { name = "sk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL" }], local_secondary_index = [{ name = "index", range_key = "sk", projection_type = "ALL" }] } } }
  expect_failures = [var.tables]
}
run "lsi_bad_index_name" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", range_key = "sk", attribute = [{ name = "pk", type = "S" }, { name = "sk", type = "S" }], local_secondary_index = [{ name = "bad!", range_key = "sk", projection_type = "ALL" }] } } }
  expect_failures = [var.tables]
}
run "lsi_invalid_projection" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", range_key = "sk", attribute = [{ name = "pk", type = "S" }, { name = "sk", type = "S" }], local_secondary_index = [{ name = "local", range_key = "sk", projection_type = "INVALID" }] } } }
  expect_failures = [var.tables]
}
run "lsi_include_without_attributes" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", range_key = "sk", attribute = [{ name = "pk", type = "S" }, { name = "sk", type = "S" }], local_secondary_index = [{ name = "local", range_key = "sk", projection_type = "INCLUDE" }] } } }
  expect_failures = [var.tables]
}
run "lsi_all_with_attributes" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", range_key = "sk", attribute = [{ name = "pk", type = "S" }, { name = "sk", type = "S" }], local_secondary_index = [{ name = "local", range_key = "sk", projection_type = "ALL", non_key_attributes = ["extra"] }] } } }
  expect_failures = [var.tables]
}
run "lsi_keys_with_attributes" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", range_key = "sk", attribute = [{ name = "pk", type = "S" }, { name = "sk", type = "S" }], local_secondary_index = [{ name = "local", range_key = "sk", projection_type = "KEYS_ONLY", non_key_attributes = ["extra"] }] } } }
  expect_failures = [var.tables]
}

run "import_backup_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], restore_backup_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source/backup/0123456789", import_table = { input_format = "CSV", s3_bucket_source = { bucket = "fake-import" } } } } }
  expect_failures = [var.tables]
}
run "import_name_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], restore_source_name = "source", import_table = { input_format = "CSV", s3_bucket_source = { bucket = "fake-import" } } } } }
  expect_failures = [var.tables]
}
run "import_source_arn_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], restore_source_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source", import_table = { input_format = "CSV", s3_bucket_source = { bucket = "fake-import" } } } } }
  expect_failures = [var.tables]
}
run "backup_name_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", restore_backup_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source/backup/0123456789", restore_source_name = "source" } } }
  expect_failures = [var.tables]
}
run "backup_source_arn_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", restore_backup_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source/backup/0123456789", restore_source_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source" } } }
  expect_failures = [var.tables]
}
run "name_source_arn_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", restore_source_name = "source", restore_source_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source" } } }
  expect_failures = [var.tables]
}
run "invalid_restore_timestamp" {
  command = plan
  variables { tables = { test = { name = "test-table", restore_source_name = "source", restore_date_time = "yesterday" } } }
  expect_failures = [var.tables]
}
run "non_utc_restore_timestamp" {
  command = plan
  variables { tables = { test = { name = "test-table", restore_source_name = "source", restore_date_time = "2026-01-01T00:00:00+01:00" } } }
  expect_failures = [var.tables]
}
run "restore_date_latest_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", restore_source_name = "source", restore_date_time = "2026-01-01T00:00:00Z", restore_to_latest_time = true } } }
  expect_failures = [var.tables]
}
run "restore_date_without_source" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], restore_date_time = "2026-01-01T00:00:00Z" } } }
  expect_failures = [var.tables]
}
run "restore_latest_without_source" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], restore_to_latest_time = true } } }
  expect_failures = [var.tables]
}
run "restore_backup_with_pitr_option" {
  command = plan
  variables { tables = { test = { name = "test-table", restore_backup_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source/backup/0123456789", restore_to_latest_time = false } } }
  expect_failures = [var.tables]
}
run "invalid_import_format" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], import_table = { input_format = "INVALID", s3_bucket_source = { bucket = "fake-import" } } } } }
  expect_failures = [var.tables]
}
run "invalid_import_compression" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], import_table = { input_format = "CSV", input_compression_type = "INVALID", s3_bucket_source = { bucket = "fake-import" } } } } }
  expect_failures = [var.tables]
}
run "csv_options_on_json" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], import_table = { input_format = "DYNAMODB_JSON", input_format_options = { csv = { delimiter = "," } }, s3_bucket_source = { bucket = "fake-import" } } } } }
  expect_failures = [var.tables]
}
run "csv_options_on_ion" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], import_table = { input_format = "ION", input_format_options = { csv = {} }, s3_bucket_source = { bucket = "fake-import" } } } } }
  expect_failures = [var.tables]
}
run "duplicate_replica_regions" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], stream_enabled = true, stream_view_type = "NEW_AND_OLD_IMAGES", replica = [{ region_name = "us-west-2" }, { region_name = "us-west-2", propagate_tags = false }] } } }
  expect_failures = [var.tables]
}
run "replica_equals_source_region" {
  command = plan
  variables { tables = { test = { name = "test-table", region = "us-west-2", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], stream_enabled = true, stream_view_type = "NEW_AND_OLD_IMAGES", replica = [{ region_name = "us-west-2" }] } } }
  expect_failures = [var.tables]
}
run "invalid_consistency_mode" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], stream_enabled = true, stream_view_type = "NEW_AND_OLD_IMAGES", replica = [{ region_name = "us-west-2", consistency_mode = "INVALID" }] } } }
  expect_failures = [var.tables]
}
run "mixed_consistency_modes" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], stream_enabled = true, stream_view_type = "NEW_AND_OLD_IMAGES", replica = [{ region_name = "us-west-2", consistency_mode = "STRONG" }, { region_name = "us-east-2" }] } } }
  expect_failures = [var.tables]
}
run "witness_equals_source" {
  command = plan
  variables { tables = { test = { name = "test-table", region = "us-east-1", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], replica = [{ region_name = "us-west-2", consistency_mode = "STRONG" }], global_table_witness = { region_name = "us-east-1" } } } }
  expect_failures = [var.tables]
}
run "witness_equals_replica" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], replica = [{ region_name = "us-west-2", consistency_mode = "STRONG" }], global_table_witness = { region_name = "us-west-2" } } } }
  expect_failures = [var.tables]
}
run "strong_one_replica_without_witness" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], replica = [{ region_name = "us-west-2", consistency_mode = "STRONG" }] } } }
  expect_failures = [var.tables]
}
run "strong_three_replicas" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], replica = [{ region_name = "us-west-2", consistency_mode = "STRONG" }, { region_name = "us-east-2", consistency_mode = "STRONG" }, { region_name = "eu-west-1", consistency_mode = "STRONG" }] } } }
  expect_failures = [var.tables]
}
run "strong_two_replicas_with_witness" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], replica = [{ region_name = "us-west-2", consistency_mode = "STRONG" }, { region_name = "us-east-2", consistency_mode = "STRONG" }], global_table_witness = { region_name = "eu-west-1" } } } }
  expect_failures = [var.tables]
}
run "strong_enabled_ttl" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], replica = [{ region_name = "us-west-2", consistency_mode = "STRONG" }, { region_name = "us-east-2", consistency_mode = "STRONG" }], ttl = { enabled = true, attribute_name = "ttl" } } } }
  expect_failures = [var.tables]
}
run "strong_lsi" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", range_key = "sk", attribute = [{ name = "pk", type = "S" }, { name = "sk", type = "S" }], local_secondary_index = [{ name = "local", range_key = "sk", projection_type = "ALL" }], replica = [{ region_name = "us-west-2", consistency_mode = "STRONG" }, { region_name = "us-east-2", consistency_mode = "STRONG" }] } } }
  expect_failures = [var.tables]
}
run "eventual_without_streams" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], replica = [{ region_name = "us-west-2" }] } } }
  expect_failures = [var.tables]
}
run "eventual_with_witness" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], stream_enabled = true, stream_view_type = "NEW_AND_OLD_IMAGES", replica = [{ region_name = "us-west-2" }], global_table_witness = { region_name = "us-east-2" } } } }
  expect_failures = [var.tables]
}
run "witness_without_replicas" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_table_witness = { region_name = "us-east-2" } } } }
  expect_failures = [var.tables]
}

variables {
  tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }] } }
}

run "null_table" {
  command = plan
  variables { tables = { test = null } }
  expect_failures = [var.tables]
}
run "invalid_billing" {
  command = plan
  variables { tables = { test = { name = "test-table", billing_mode = "INVALID" } } }
  expect_failures = [var.tables]
}
run "invalid_class" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], table_class = "INVALID" } } }
  expect_failures = [var.tables]
}
run "invalid_attribute_type" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "X" }] } } }
  expect_failures = [var.tables]
}
run "missing_partition_key" {
  command = plan
  variables { tables = { test = { name = "test-table" } } }
  expect_failures = [var.tables]
}
run "empty_partition_key" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = " " } } }
  expect_failures = [var.tables]
}
run "missing_key_attribute" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk" } } }
  expect_failures = [var.tables]
}
run "duplicate_attribute" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }, { name = "pk", type = "N" }] } } }
  expect_failures = [var.tables]
}
run "unused_attribute" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }, { name = "ttl", type = "N" }] } } }
  expect_failures = [var.tables]
}
run "missing_gsi_attribute" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "missing", projection_type = "ALL" }] } } }
  expect_failures = [var.tables]
}
run "missing_ordered_attribute" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", key_schema = [{ attribute_name = "missing", key_type = "HASH" }], projection_type = "ALL" }] } } }
  expect_failures = [var.tables]
}
run "bad_index_name" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "a!", hash_key = "pk", projection_type = "ALL" }] } } }
  expect_failures = [var.tables]
}
run "short_index_name" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "ab", hash_key = "pk", projection_type = "ALL" }] } } }
  expect_failures = [var.tables]
}
run "long_index_name" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = join("", [for i in range(256) : "a"]), hash_key = "pk", projection_type = "ALL" }] } } }
  expect_failures = [var.tables]
}
run "duplicate_index_names" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL" }, { name = "index", hash_key = "pk", projection_type = "KEYS_ONLY" }] } } }
  expect_failures = [var.tables]
}
run "lsi_without_sort_key" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], local_secondary_index = [{ name = "local", range_key = "pk", projection_type = "ALL" }] } } }
  expect_failures = [var.tables]
}
run "missing_provisioned_read" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], billing_mode = "PROVISIONED", write_capacity = 1 } } }
  expect_failures = [var.tables]
}
run "missing_provisioned_write" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], billing_mode = "PROVISIONED", read_capacity = 1 } } }
  expect_failures = [var.tables]
}
run "nonpositive_read" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], billing_mode = "PROVISIONED", read_capacity = 0, write_capacity = 1 } } }
  expect_failures = [var.tables]
}
run "nonpositive_write" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], billing_mode = "PROVISIONED", read_capacity = 1, write_capacity = -1 } } }
  expect_failures = [var.tables]
}
run "fractional_read" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], billing_mode = "PROVISIONED", read_capacity = 1.5, write_capacity = 1 } } }
  expect_failures = [var.tables]
}
run "fractional_write" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], billing_mode = "PROVISIONED", read_capacity = 1, write_capacity = 1.5 } } }
  expect_failures = [var.tables]
}
run "on_demand_read_capacity" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], read_capacity = 1 } } }
  expect_failures = [var.tables]
}
run "on_demand_write_capacity" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], write_capacity = 1 } } }
  expect_failures = [var.tables]
}
run "missing_gsi_read" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], billing_mode = "PROVISIONED", read_capacity = 1, write_capacity = 1, global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", write_capacity = 1 }] } } }
  expect_failures = [var.tables]
}
run "missing_gsi_write" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], billing_mode = "PROVISIONED", read_capacity = 1, write_capacity = 1, global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", read_capacity = 1 }] } } }
  expect_failures = [var.tables]
}
run "provisioned_cap_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], billing_mode = "PROVISIONED", read_capacity = 1, write_capacity = 1, on_demand_throughput = { max_read_request_units = 10 } } } }
  expect_failures = [var.tables]
}
run "zero_read_cap" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], on_demand_throughput = { max_read_request_units = 0 } } } }
  expect_failures = [var.tables]
}
run "negative_read_cap" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], on_demand_throughput = { max_read_request_units = -2 } } } }
  expect_failures = [var.tables]
}
run "fractional_read_cap" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], on_demand_throughput = { max_read_request_units = 1.5 } } } }
  expect_failures = [var.tables]
}
run "zero_write_cap" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], on_demand_throughput = { max_write_request_units = 0 } } } }
  expect_failures = [var.tables]
}
run "negative_write_cap" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], on_demand_throughput = { max_write_request_units = -2 } } } }
  expect_failures = [var.tables]
}
run "fractional_write_cap" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], on_demand_throughput = { max_write_request_units = 1.5 } } } }
  expect_failures = [var.tables]
}
run "warm_reads_below_minimum" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], warm_throughput = { read_units_per_second = 11999 } } } }
  expect_failures = [var.tables]
}
run "warm_reads_fractional" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], warm_throughput = { read_units_per_second = 12000.5 } } } }
  expect_failures = [var.tables]
}
run "warm_writes_below_minimum" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], warm_throughput = { write_units_per_second = 3999 } } } }
  expect_failures = [var.tables]
}
run "warm_writes_fractional" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], warm_throughput = { write_units_per_second = 4000.5 } } } }
  expect_failures = [var.tables]
}
run "recovery_below_minimum" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], point_in_time_recovery = { recovery_period_in_days = 0 } } } }
  expect_failures = [var.tables]
}
run "recovery_above_maximum" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], point_in_time_recovery = { recovery_period_in_days = 36 } } } }
  expect_failures = [var.tables]
}
run "recovery_fractional" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], point_in_time_recovery = { recovery_period_in_days = 1.5 } } } }
  expect_failures = [var.tables]
}
run "ttl_missing_name" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], ttl = { enabled = true } } } }
  expect_failures = [var.tables]
}
run "ttl_empty_name" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], ttl = { enabled = true, attribute_name = "" } } } }
  expect_failures = [var.tables]
}
run "stream_missing_view" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], stream_enabled = true } } }
  expect_failures = [var.tables]
}
run "stream_invalid_view" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], stream_enabled = true, stream_view_type = "INVALID" } } }
  expect_failures = [var.tables]
}
run "view_without_stream" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], stream_view_type = "NEW_IMAGE" } } }
  expect_failures = [var.tables]
}
run "invalid_projection" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "INVALID" }] } } }
  expect_failures = [var.tables]
}
run "include_without_attributes" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "INCLUDE" }] } } }
  expect_failures = [var.tables]
}
run "all_with_attributes" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "ALL", non_key_attributes = ["extra"] }] } } }
  expect_failures = [var.tables]
}
run "keys_only_with_attributes" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", projection_type = "KEYS_ONLY", non_key_attributes = ["extra"] }] } } }
  expect_failures = [var.tables]
}
run "missing_gsi_key" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", projection_type = "ALL" }] } } }
  expect_failures = [var.tables]
}
run "ordered_missing_hash" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", key_schema = [{ attribute_name = "pk", key_type = "RANGE" }], projection_type = "ALL" }] } } }
  expect_failures = [var.tables]
}
run "ordered_invalid_key_type" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", key_schema = [{ attribute_name = "pk", key_type = "INVALID" }], projection_type = "ALL" }] } } }
  expect_failures = [var.tables]
}
run "ordered_duplicate_attribute" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", key_schema = [{ attribute_name = "pk", key_type = "HASH" }, { attribute_name = "pk", key_type = "RANGE" }], projection_type = "ALL" }] } } }
  expect_failures = [var.tables]
}
run "ordered_hash_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", hash_key = "pk", key_schema = [{ attribute_name = "pk", key_type = "HASH" }], projection_type = "ALL" }] } } }
  expect_failures = [var.tables]
}
run "ordered_range_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], global_secondary_index = [{ name = "index", range_key = "pk", key_schema = [{ attribute_name = "pk", key_type = "HASH" }], projection_type = "ALL" }] } } }
  expect_failures = [var.tables]
}
run "ordered_five_hashes" {
  command = plan
  variables {
    tables = { test = {
      name                   = "test-table", hash_key = "pk"
      attribute              = concat([{ name = "pk", type = "S" }], [for i in range(5) : { name = "key${i}", type = "S" }])
      global_secondary_index = [{ name = "index", projection_type = "ALL", key_schema = [for i in range(5) : { attribute_name = "key${i}", key_type = "HASH" }] }]
    } }
  }
  expect_failures = [var.tables]
}
run "ordered_five_ranges" {
  command = plan
  variables {
    tables = { test = {
      name                   = "test-table", hash_key = "pk"
      attribute              = concat([{ name = "pk", type = "S" }], [for i in range(5) : { name = "key${i}", type = "S" }])
      global_secondary_index = [{ name = "index", projection_type = "ALL", key_schema = concat([{ attribute_name = "pk", key_type = "HASH" }], [for i in range(5) : { attribute_name = "key${i}", key_type = "RANGE" }]) }]
    } }
  }
  expect_failures = [var.tables]
}
