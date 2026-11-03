mock_provider "aws" {}

variables {
  tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }] } }
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