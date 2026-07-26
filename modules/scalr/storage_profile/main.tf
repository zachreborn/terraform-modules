###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.17.0"
    }
  }
}

###########################
# Scalr Storage Profile
###########################

resource "scalr_storage_profile" "this" {
  for_each = var.storage_profiles

  name    = coalesce(each.value.name, each.key)
  default = each.value.default

  dynamic "aws_s3" {
    for_each = each.value.aws_s3 != null ? [each.value.aws_s3] : []
    content {
      audience    = aws_s3.value.audience
      bucket_name = aws_s3.value.bucket_name
      role_arn    = aws_s3.value.role_arn
      region      = aws_s3.value.region
    }
  }

  dynamic "azurerm" {
    for_each = each.value.azurerm != null ? [each.value.azurerm] : []
    content {
      audience        = azurerm.value.audience
      client_id       = azurerm.value.client_id
      container_name  = azurerm.value.container_name
      storage_account = azurerm.value.storage_account
      tenant_id       = azurerm.value.tenant_id
    }
  }

  dynamic "google" {
    for_each = each.value.google != null ? [each.value.google] : []
    content {
      storage_bucket = google.value.storage_bucket
      project        = google.value.project
      credentials    = lookup(var.google_credentials, each.key, null)
      encryption_key = lookup(var.google_encryption_keys, each.key, null)
    }
  }
}
