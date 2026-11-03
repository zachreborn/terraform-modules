mock_provider "aws" {}

variables {
  tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }] } }
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