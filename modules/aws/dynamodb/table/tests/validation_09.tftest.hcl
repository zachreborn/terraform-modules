mock_provider "aws" {}

variables {
  tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }] } }
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