############################
# Data Sources
############################

data "azuread_client_config" "current" {}

############################
# Azure AD Group
############################

resource "azuread_group" "this" {
  auto_subscribe_new_members = var.auto_subscribe_new_members
  description                = var.description
  display_name               = var.display_name
  external_senders_allowed   = var.external_senders_allowed
  hide_from_address_lists    = var.hide_from_address_lists
  hide_from_outlook_clients  = var.hide_from_outlook_clients
  mail_enabled               = var.mail_enabled
  mail_nickname              = var.mail_nickname
  members                    = var.members
  owners                     = var.owners
  prevent_duplicate_names    = var.prevent_duplicate_names
  provisioning_options       = var.provisioning_options
  security_enabled           = var.security_enabled
  types                      = var.types
  visibility                 = var.visibility

  dynamic "dynamic_membership" {
    for_each = var.dynamic_membership == null ? [] : [var.dynamic_membership]
    content {
      enabled = try(dynamic_membership.value.enabled, null)
      rule    = try(dynamic_membership.value.rule, null)
    }
  }
}
