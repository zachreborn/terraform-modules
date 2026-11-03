mock_provider "aws" {}

variables {
  tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }] } }
}

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