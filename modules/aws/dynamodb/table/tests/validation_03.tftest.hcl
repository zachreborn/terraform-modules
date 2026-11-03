mock_provider "aws" {}

variables {
  tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }] } }
}


run "lsi_invalid_projection" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", range_key = "sk", attribute = [{ name = "pk", type = "S" }, { name = "sk", type = "S" }], local_secondary_index = [{ name = "local", range_key = "sk", projection_type = "INVALID" }] } } }
  expect_failures = [var.tables]
}
run "lsi_include_without_attributes" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", range_key = "sk", attribute = [{ name = "pk", type = "S" }, { name = "sk", type = "S" }], local_secondary_index = [{ name = "local", range_key = "sk", projection_type = "INCLUDE" }] } } }
  expect_failures = [var.tables]
}
run "lsi_all_with_attributes" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", range_key = "sk", attribute = [{ name = "pk", type = "S" }, { name = "sk", type = "S" }], local_secondary_index = [{ name = "local", range_key = "sk", projection_type = "ALL", non_key_attributes = ["extra"] }] } } }
  expect_failures = [var.tables]
}
run "lsi_keys_with_attributes" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", range_key = "sk", attribute = [{ name = "pk", type = "S" }, { name = "sk", type = "S" }], local_secondary_index = [{ name = "local", range_key = "sk", projection_type = "KEYS_ONLY", non_key_attributes = ["extra"] }] } } }
  expect_failures = [var.tables]
}

run "import_backup_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], restore_backup_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source/backup/0123456789", import_table = { input_format = "CSV", s3_bucket_source = { bucket = "fake-import" } } } } }
  expect_failures = [var.tables]
}
run "import_name_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], restore_source_name = "source", import_table = { input_format = "CSV", s3_bucket_source = { bucket = "fake-import" } } } } }
  expect_failures = [var.tables]
}
run "import_source_arn_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", hash_key = "pk", attribute = [{ name = "pk", type = "S" }], restore_source_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source", import_table = { input_format = "CSV", s3_bucket_source = { bucket = "fake-import" } } } } }
  expect_failures = [var.tables]
}
run "backup_name_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", restore_backup_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source/backup/0123456789", restore_source_name = "source" } } }
  expect_failures = [var.tables]
}
run "backup_source_arn_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", restore_backup_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source/backup/0123456789", restore_source_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source" } } }
  expect_failures = [var.tables]
}
run "name_source_arn_conflict" {
  command = plan
  variables { tables = { test = { name = "test-table", restore_source_name = "source", restore_source_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source" } } }
  expect_failures = [var.tables]
}