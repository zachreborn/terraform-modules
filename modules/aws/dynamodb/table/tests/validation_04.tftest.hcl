mock_provider "aws" {}

variables {
  tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }] } }
}


run "invalid_restore_timestamp" {
  command = plan
  variables { tables = { test = { name = "test-table", restore_source_name = "source", restore_date_time = "yesterday" } } }
  expect_failures = [var.tables]
}
run "non_utc_restore_timestamp" {
  command = plan
  variables { tables = { test = { name = "test-table", restore_source_name = "source", restore_date_time = "2026-01-01T00:00:00+01:00" } } }
  expect_failures = [var.tables]
}
run "restore_date_latest_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", restore_source_name = "source", restore_date_time = "2026-01-01T00:00:00Z", restore_to_latest_time = true } } }
  expect_failures = [var.tables]
}
run "restore_date_without_source" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], restore_date_time = "2026-01-01T00:00:00Z" } } }
  expect_failures = [var.tables]
}
run "restore_latest_without_source" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], restore_to_latest_time = true } } }
  expect_failures = [var.tables]
}
run "restore_backup_with_pitr_option" {
  command = plan
  variables { tables = { test = { name = "test-table", restore_backup_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source/backup/0123456789", restore_to_latest_time = false } } }
  expect_failures = [var.tables]
}
run "invalid_import_format" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], import_table = { input_format = "INVALID", s3_bucket_source = { bucket = "fake-import" } } } } }
  expect_failures = [var.tables]
}
run "invalid_import_compression" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], import_table = { input_format = "CSV", input_compression_type = "INVALID", s3_bucket_source = { bucket = "fake-import" } } } } }
  expect_failures = [var.tables]
}
run "csv_options_on_json" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], import_table = { input_format = "DYNAMODB_JSON", input_format_options = { csv = { delimiter = "," } }, s3_bucket_source = { bucket = "fake-import" } } } } }
  expect_failures = [var.tables]
}
run "csv_options_on_ion" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], import_table = { input_format = "ION", input_format_options = { csv = {} }, s3_bucket_source = { bucket = "fake-import" } } } } }
  expect_failures = [var.tables]
}