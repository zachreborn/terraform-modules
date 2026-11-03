mock_provider "aws" {}

variables {
  tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }] } }
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