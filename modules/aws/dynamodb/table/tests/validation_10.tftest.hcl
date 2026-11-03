mock_provider "aws" {}

variables {
  tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }] } }
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