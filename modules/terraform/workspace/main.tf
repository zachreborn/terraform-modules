terraform {
  required_version = ">= 1.0.0"
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">=0.42.0"
    }
  }
}

##############################
# Data Sources
##############################
data "tls_certificate" "terraform_cloud_certificate" {
  url = "https://${var.terraform_cloud_hostname}"
}

##############################
# Terraform Workspace
##############################

resource "tfe_workspace" "this" {
  agent_pool_id                 = var.agent_pool_id
  allow_destroy_plan            = var.allow_destroy_plan
  auto_apply                    = var.auto_apply
  assessments_enabled           = var.assessments_enabled
  description                   = var.description
  execution_mode                = var.execution_mode
  file_triggers_enabled         = var.file_triggers_enabled
  global_remote_state           = var.global_remote_state
  name                          = var.name
  organization                  = var.organization
  queue_all_runs                = var.queue_all_runs
  remote_state_consumer_ids     = var.remote_state_consumer_ids
  speculative_enabled           = var.speculative_enabled
  ssh_key_id                    = var.ssh_key_id
  structured_run_output_enabled = var.structured_run_output_enabled
  terraform_version             = var.terraform_version
  trigger_prefixes              = var.trigger_prefixes
  tag_names                     = var.tag_names
  working_directory             = var.working_directory
  vcs_repo {
    identifier         = var.identifier
    branch             = var.branch
    ingress_submodules = var.ingress_submodules
    oauth_token_id     = var.oauth_token_id
  }
}

##############################
# Terraform Team Access/Permissions
##############################

resource "tfe_team_access" "this" {
  for_each     = var.permission_map
  team_id      = each.value.id
  workspace_id = tfe_workspace.this.id
  access       = each.value.access
}

##############################
# Workspace Variables
##############################
# Used if enable_dynamic_credentials is true
# This is used by the Terraform Cloud workspace to authentication dynamically with the provider and should be enabled for best practice authentication
resource "tfe_variable" "tfc_aws_provider_auth" {
  count        = var.enable_dynamic_credentials ? 1 : 0
  workspace_id = tfe_workspace.this.id
  category     = "env"
  description  = "Enable dynamic authentication with AWS identity provider."
  key          = "TFC_AWS_PROVIDER_AUTH"
  value        = "true"
}

resource "tfe_variable" "tfc_aws_run_role_arn" {
  count        = var.enable_dynamic_credentials ? 1 : 0
  workspace_id = tfe_workspace.this.id
  category     = "env"
  description  = "The AWS role arn the workspace will use to authenticate."
  key          = "TFC_AWS_RUN_ROLE_ARN"
  value        = var.dynamic_role_arn
}

##############################
# AWS Identity Provider
##############################
# Used if enable_aws is true
resource "aws_iam_openid_connect_provider" "terraform_cloud" {
  count = var.enable_aws ? 1 : 0
  url   = data.tls_certificate.terraform_cloud_certificate.url
  tags  = var.tags
  client_id_list = [
    var.terraform_cloud_aws_audience
  ]
  thumbprint_list = [
    data.tls_certificate.terraform_cloud_certificate.certificates[0].sha1_fingerprint
  ]
}

resource "aws_iam_role" "terraform_cloud" {
  count = var.enable_aws ? 1 : 0
  name  = var.iam_role_name
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Principal" = {
          "Federated" = "${aws_iam_openid_connect_provider.terraform_cloud[0].arn}"
        },
        "Action" = "sts:AssumeRoleWithWebIdentity",
        "Condition" = {
          "StringEquals" = {
            "${var.terraform_cloud_hostname}:aud" : "${var.terraform_cloud_aws_audience}"
          },
          "StringLike" = {
            "${var.terraform_cloud_hostname}:sub" : "organization:${var.organization}:project:${var.terraform_cloud_project_name}:workspace:${var.name}:run_phase:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_cloud" {
  count      = var.enable_aws ? 1 : 0
  role       = aws_iam_role.terraform_cloud[0].name
  policy_arn = var.terraform_role_policy_arn
}
