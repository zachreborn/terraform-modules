mock_provider "aws" {}

variables {
  tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }] } }
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