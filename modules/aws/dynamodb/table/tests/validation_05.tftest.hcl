mock_provider "aws" {}

variables {
  tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }] } }
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