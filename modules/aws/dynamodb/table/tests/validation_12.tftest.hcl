mock_provider "aws" {}

variables {
  tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }] } }
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
