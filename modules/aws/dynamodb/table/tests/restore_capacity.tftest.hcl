mock_provider "aws" {}

run "backup_restore_requires_configured_index_capacities" {
  command = plan
  variables {
    tables = {
      restored = {
        name               = "restored-backup"
        billing_mode       = "PROVISIONED"
        restore_backup_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source/backup/0123456789"
        hash_key           = "pk"
        attribute          = [{ name = "pk", type = "S" }]
        global_secondary_index = [{
          name            = "by-key"
          projection_type = "ALL"
          key_schema      = [{ attribute_name = "pk", key_type = "HASH" }]
        }]
      }
    }
  }
  expect_failures = [var.tables]
}

run "named_restore_requires_configured_index_capacities" {
  command = plan
  variables {
    tables = {
      restored = {
        name                = "restored-name"
        billing_mode        = "PROVISIONED"
        restore_source_name = "source"
        hash_key            = "pk"
        attribute           = [{ name = "pk", type = "S" }]
        global_secondary_index = [{
          name            = "by-key"
          projection_type = "ALL"
          key_schema      = [{ attribute_name = "pk", key_type = "HASH" }]
        }]
      }
    }
  }
  expect_failures = [var.tables]
}

run "source_arn_restore_requires_configured_index_capacities" {
  command = plan
  variables {
    tables = {
      restored = {
        name                     = "restored-arn"
        billing_mode             = "PROVISIONED"
        restore_source_table_arn = "arn:aws:dynamodb:us-east-1:123456789012:table/source"
        hash_key                 = "pk"
        attribute                = [{ name = "pk", type = "S" }]
        global_secondary_index = [{
          name            = "by-key"
          projection_type = "ALL"
          key_schema      = [{ attribute_name = "pk", key_type = "HASH" }]
        }]
      }
    }
  }
  expect_failures = [var.tables]
}

run "restored_index_requires_read_capacity" {
  command = plan
  variables {
    tables = {
      restored = {
        name                = "restored-name"
        billing_mode        = "PROVISIONED"
        restore_source_name = "source"
        hash_key            = "pk"
        attribute           = [{ name = "pk", type = "S" }]
        global_secondary_index = [{
          name            = "by-key"
          projection_type = "ALL"
          key_schema      = [{ attribute_name = "pk", key_type = "HASH" }]
          write_capacity  = 1
        }]
      }
    }
  }
  expect_failures = [var.tables]
}

run "restored_index_requires_write_capacity" {
  command = plan
  variables {
    tables = {
      restored = {
        name                = "restored-name"
        billing_mode        = "PROVISIONED"
        restore_source_name = "source"
        hash_key            = "pk"
        attribute           = [{ name = "pk", type = "S" }]
        global_secondary_index = [{
          name            = "by-key"
          projection_type = "ALL"
          key_schema      = [{ attribute_name = "pk", key_type = "HASH" }]
          read_capacity   = 1
        }]
      }
    }
  }
  expect_failures = [var.tables]
}

run "restored_base_table_cannot_omit_only_read_capacity" {
  command = plan
  variables {
    tables = {
      restored = {
        name                = "restored-name"
        billing_mode        = "PROVISIONED"
        restore_source_name = "source"
        write_capacity      = 1
      }
    }
  }
  expect_failures = [var.tables]
}

run "restored_base_table_cannot_omit_only_write_capacity" {
  command = plan
  variables {
    tables = {
      restored = {
        name                = "restored-name"
        billing_mode        = "PROVISIONED"
        restore_source_name = "source"
        read_capacity       = 1
      }
    }
  }
  expect_failures = [var.tables]
}

run "all_provisioned_restore_selectors_inherit_only_base_capacities" {
  command = plan
  variables {
    tables = { for source in ["backup", "name", "arn"] : source => {
      name                     = "restored-${source}"
      billing_mode             = "PROVISIONED"
      restore_backup_arn       = source == "backup" ? "arn:aws:dynamodb:us-east-1:123456789012:table/source/backup/0123456789" : null
      restore_source_name      = source == "name" ? "source" : null
      restore_source_table_arn = source == "arn" ? "arn:aws:dynamodb:us-east-1:123456789012:table/source" : null
    } }
  }
  assert {
    condition     = toset(keys(aws_dynamodb_table.this)) == toset(["backup", "name", "arn"]) && alltrue([for t in var.tables : try(t.read_capacity, null) == null && try(t.write_capacity, null) == null]) && alltrue([for t in aws_dynamodb_table.this : t.billing_mode == "PROVISIONED" && length(t.global_secondary_index) == 0])
    error_message = "All restore selectors must still permit both base-table capacities to be inherited when no indexes are configured."
  }
}

run "all_provisioned_restore_selectors_forward_explicit_index_capacities" {
  command = plan
  variables {
    tables = { for source in ["backup", "name", "arn"] : source => {
      name                     = "restored-${source}"
      billing_mode             = "PROVISIONED"
      restore_backup_arn       = source == "backup" ? "arn:aws:dynamodb:us-east-1:123456789012:table/source/backup/0123456789" : null
      restore_source_name      = source == "name" ? "source" : null
      restore_source_table_arn = source == "arn" ? "arn:aws:dynamodb:us-east-1:123456789012:table/source" : null
      hash_key                 = "pk"
      attribute                = [{ name = "pk", type = "S" }]
      global_secondary_index = [{
        name            = "by-key"
        projection_type = "ALL"
        key_schema      = [{ attribute_name = "pk", key_type = "HASH" }]
        read_capacity   = 1
        write_capacity  = 2
      }]
    } }
  }
  assert {
    condition     = toset(keys(aws_dynamodb_table.this)) == toset(["backup", "name", "arn"]) && alltrue([for t in var.tables : try(t.read_capacity, null) == null && try(t.write_capacity, null) == null]) && alltrue([for t in aws_dynamodb_table.this : one(t.global_secondary_index).read_capacity == 1 && one(t.global_secondary_index).write_capacity == 2])
    error_message = "Configured restore indexes must receive their exact positive capacities while base-table capacities remain inherited."
  }
}

run "on_demand_restore_indexes_omit_provisioned_capacities" {
  command = plan
  variables {
    tables = { for source in ["backup", "name", "arn"] : source => {
      name                     = "restored-${source}"
      billing_mode             = "PAY_PER_REQUEST"
      restore_backup_arn       = source == "backup" ? "arn:aws:dynamodb:us-east-1:123456789012:table/source/backup/0123456789" : null
      restore_source_name      = source == "name" ? "source" : null
      restore_source_table_arn = source == "arn" ? "arn:aws:dynamodb:us-east-1:123456789012:table/source" : null
      hash_key                 = "pk"
      attribute                = [{ name = "pk", type = "S" }]
      global_secondary_index = [{
        name            = "by-key"
        projection_type = "ALL"
        key_schema      = [{ attribute_name = "pk", key_type = "HASH" }]
      }]
    } }
  }
  assert {
    condition     = toset(keys(aws_dynamodb_table.this)) == toset(["backup", "name", "arn"]) && alltrue([for t in var.tables : try(t.read_capacity, null) == null && try(t.write_capacity, null) == null && alltrue([for i in t.global_secondary_index : try(i.read_capacity, null) == null && try(i.write_capacity, null) == null])]) && alltrue([for t in aws_dynamodb_table.this : t.billing_mode == "PAY_PER_REQUEST" && length(t.global_secondary_index) == 1])
    error_message = "On-demand restores must retain the no-provisioned-units contract for the table and every configured index."
  }
}
