resource "tfe_organization" "this" {
  allow_force_delete_workspaces                           = var.allow_force_delete_workspaces
  assessments_enforced                                    = var.assessments_enforced
  collaborator_auth_policy                                = var.collaborator_auth_policy
  cost_estimation_enabled                                 = var.cost_estimation_enabled
  email                                                   = var.email
  name                                                    = var.name
  owners_team_saml_role_id                                = var.owners_team_saml_role_id
  session_timeout_minutes                                 = var.session_timeout_minutes
  session_remember_minutes                                = var.session_remember_minutes
  send_passing_statuses_for_untriggered_speculative_plans = var.send_passing_statuses_for_untriggered_speculative_plans
}
