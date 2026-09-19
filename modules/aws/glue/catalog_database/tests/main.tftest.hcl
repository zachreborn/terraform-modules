mock_provider "aws" {
  mock_resource "aws_glue_catalog_database" {
    defaults = {
      id  = "123456789012:example_database"
      arn = "arn:aws:glue:us-east-1:123456789012:database/example_database"
    }
  }
}

# Note: catalog_id is Optional+Computed in the aws_glue_catalog_database schema (it defaults
# to the AWS account ID when omitted), so it intentionally has no fixed mock default here --
# OpenTofu rejects a mock default for a field that a run elsewhere sets explicitly via config
# (see the "overrides_are_honored" run below). There is no meaningful "defaults to null" case
# to assert via mocks for this field.

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    name = "example_database"
  }

  assert {
    condition     = aws_glue_catalog_database.this.name == "example_database"
    error_message = "name should be passed through to the resource."
  }

  assert {
    condition     = aws_glue_catalog_database.this.tags["Name"] == "example_database"
    error_message = "tags should default to include Name = var.name."
  }

  assert {
    condition     = length(aws_glue_catalog_database.this.create_table_default_permission) == 0
    error_message = "create_table_default_permission should default to no blocks when unset."
  }

  assert {
    condition     = length(aws_glue_catalog_database.this.federated_database) == 0
    error_message = "federated_database should default to no blocks when unset."
  }

  assert {
    condition     = length(aws_glue_catalog_database.this.target_database) == 0
    error_message = "target_database should default to no blocks when unset."
  }

  assert {
    condition     = output.id == "123456789012:example_database"
    error_message = "id output should expose the mocked resource id."
  }

  assert {
    condition     = output.arn == "arn:aws:glue:us-east-1:123456789012:database/example_database"
    error_message = "arn output should expose the mocked resource arn."
  }

  assert {
    condition     = output.name == "example_database"
    error_message = "name output should expose the resource's name attribute."
  }

  assert {
    condition     = output.catalog_id == aws_glue_catalog_database.this.catalog_id
    error_message = "catalog_id output should expose the resource's catalog_id attribute."
  }
}

run "overrides_are_honored" {
  command = plan

  variables {
    name         = "feature_store"
    catalog_id   = "987654321098"
    description  = "ML feature store backed by S3"
    location_uri = "s3://my-data-lake/feature_store/"
    parameters = {
      classification = "parquet"
    }
    tags = {
      team = "platform"
    }
  }

  assert {
    condition     = aws_glue_catalog_database.this.catalog_id == "987654321098"
    error_message = "catalog_id override should be honored."
  }

  assert {
    condition     = aws_glue_catalog_database.this.description == "ML feature store backed by S3"
    error_message = "description override should be honored."
  }

  assert {
    condition     = aws_glue_catalog_database.this.location_uri == "s3://my-data-lake/feature_store/"
    error_message = "location_uri override should be honored."
  }

  assert {
    condition     = aws_glue_catalog_database.this.parameters["classification"] == "parquet"
    error_message = "parameters override should be honored."
  }

  assert {
    condition     = aws_glue_catalog_database.this.tags["team"] == "platform"
    error_message = "Custom tags should be merged into the resource tags."
  }
}

run "create_table_default_permission_block_is_emitted_when_set" {
  command = plan

  variables {
    name = "example_database"
    create_table_default_permission = {
      permissions = ["ALL"]
      principal = {
        data_lake_principal_identifier = "IAM_ALLOWED_PRINCIPALS"
      }
    }
  }

  assert {
    condition     = length(aws_glue_catalog_database.this.create_table_default_permission) == 1
    error_message = "create_table_default_permission should emit exactly one block when set."
  }

  assert {
    condition     = contains(aws_glue_catalog_database.this.create_table_default_permission[0].permissions, "ALL")
    error_message = "create_table_default_permission.permissions should be wired through."
  }

  assert {
    condition     = aws_glue_catalog_database.this.create_table_default_permission[0].principal[0].data_lake_principal_identifier == "IAM_ALLOWED_PRINCIPALS"
    error_message = "create_table_default_permission.principal.data_lake_principal_identifier should be wired through."
  }
}

run "federated_database_block_is_emitted_when_set" {
  command = plan

  variables {
    name = "shared_link"
    federated_database = {
      connection_name = "example-connection"
      identifier      = "arn:aws:glue:us-east-1:123456789012:database/source_database"
    }
  }

  assert {
    condition     = length(aws_glue_catalog_database.this.federated_database) == 1
    error_message = "federated_database should emit exactly one block when set."
  }

  assert {
    condition     = aws_glue_catalog_database.this.federated_database[0].connection_name == "example-connection"
    error_message = "federated_database.connection_name should be wired through."
  }

  assert {
    condition     = aws_glue_catalog_database.this.federated_database[0].identifier == "arn:aws:glue:us-east-1:123456789012:database/source_database"
    error_message = "federated_database.identifier should be wired through."
  }
}

run "target_database_block_is_emitted_when_set" {
  command = plan

  variables {
    name = "shared_database_link"
    target_database = {
      catalog_id    = "123456789012"
      database_name = "shared_source"
    }
  }

  assert {
    condition     = length(aws_glue_catalog_database.this.target_database) == 1
    error_message = "target_database should emit exactly one block when set."
  }

  assert {
    condition     = aws_glue_catalog_database.this.target_database[0].catalog_id == "123456789012"
    error_message = "target_database.catalog_id should be wired through."
  }

  assert {
    condition     = aws_glue_catalog_database.this.target_database[0].database_name == "shared_source"
    error_message = "target_database.database_name should be wired through."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
