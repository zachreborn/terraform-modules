mock_provider "aws" {}

variables {
  tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }] } }
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