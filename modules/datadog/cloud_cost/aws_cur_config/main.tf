###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = ">= 4.0.0"
    }
  }
}

###########################
# Locals
###########################

###########################
# Module Configuration
###########################
resource "datadog_aws_cur_config" "this" {
  for_each = var.aws_cur_configs

  account_id    = each.value.account_id
  bucket_name   = each.value.bucket_name
  bucket_region = each.value.bucket_region
  report_name   = each.value.report_name
  report_prefix = each.value.report_prefix

  dynamic "account_filters" {
    for_each = each.value.account_filters != null ? [each.value.account_filters] : []
    content {
      include_new_accounts = account_filters.value.include_new_accounts
      excluded_accounts    = account_filters.value.excluded_accounts
      included_accounts    = account_filters.value.included_accounts
    }
  }
}
