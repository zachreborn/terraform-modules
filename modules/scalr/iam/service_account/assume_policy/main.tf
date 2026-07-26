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
  resolved_assume_policies = {
    for k, v in var.assume_policies : k => merge(v, {
      service_account_id = v.service_account_key != null ? lookup(var.service_account_ids, v.service_account_key, null) : v.service_account_id
    })
  }
}

###########################
# Module Configuration
###########################
resource "scalr_assume_service_account_policy" "this" {
  for_each = local.resolved_assume_policies

  name                     = coalesce(each.value.name, each.key)
  provider_id              = each.value.provider_id
  service_account_id       = each.value.service_account_id
  maximum_session_duration = each.value.maximum_session_duration

  dynamic "claim_condition" {
    for_each = each.value.claim_conditions
    content {
      claim    = claim_condition.value.claim
      value    = claim_condition.value.value
      operator = claim_condition.value.operator
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.service_account_key == null || contains(keys(var.service_account_ids), each.value.service_account_key)
      error_message = "service_account_key \"${each.value.service_account_key != null ? each.value.service_account_key : "(none)"}\" was not found in var.service_account_ids. Pass the service_account module's `ids` output through as service_account_ids."
    }
  }
}
