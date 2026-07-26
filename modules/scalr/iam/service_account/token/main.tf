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
# Data Sources
###########################


###########################
# Locals
###########################
locals {
  # Resolve each entry's service_account_id: either the literal service_account_id, or a lookup of
  # service_account_key against the caller-supplied service_account_ids map (e.g. the `ids` output
  # of modules/scalr/iam/service_account, when composed by that parent module).
  resolved_tokens = {
    for k, v in var.tokens : k => merge(v, {
      service_account_id = v.service_account_key != null ? lookup(var.service_account_ids, v.service_account_key, null) : v.service_account_id
    })
  }
}

###########################
# Module Configuration
###########################
resource "scalr_service_account_token" "this" {
  for_each = local.resolved_tokens

  service_account_id = each.value.service_account_id
  description        = each.value.description
  expires_in         = each.value.expires_in
  name               = each.value.name

  lifecycle {
    precondition {
      condition     = each.value.service_account_key == null || contains(keys(var.service_account_ids), each.value.service_account_key)
      error_message = "service_account_key \"${each.value.service_account_key != null ? each.value.service_account_key : "(none)"}\" was not found in var.service_account_ids. Pass the service_account module's `ids` output through as service_account_ids."
    }
  }
}
