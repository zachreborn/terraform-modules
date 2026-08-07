##############################
# Provider Configuration
##############################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

##############################
# Glue Catalog Database
##############################
resource "aws_glue_catalog_database" "this" {
  name         = var.name
  catalog_id   = var.catalog_id
  description  = var.description
  location_uri = var.location_uri
  parameters   = var.parameters
  tags         = merge(tomap({ Name = var.name }), var.tags)

  dynamic "create_table_default_permission" {
    for_each = var.create_table_default_permission != null ? [var.create_table_default_permission] : []
    content {
      permissions = create_table_default_permission.value.permissions

      dynamic "principal" {
        for_each = create_table_default_permission.value.principal != null ? [create_table_default_permission.value.principal] : []
        content {
          data_lake_principal_identifier = principal.value.data_lake_principal_identifier
        }
      }
    }
  }

  dynamic "federated_database" {
    for_each = var.federated_database != null ? [var.federated_database] : []
    content {
      connection_name = federated_database.value.connection_name
      identifier      = federated_database.value.identifier
    }
  }

  dynamic "target_database" {
    for_each = var.target_database != null ? [var.target_database] : []
    content {
      catalog_id    = target_database.value.catalog_id
      database_name = target_database.value.database_name
      region        = target_database.value.region
    }
  }
}
