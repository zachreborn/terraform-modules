mock_provider "aws" {
  mock_resource "aws_organizations_organization" {
    defaults = {
      roots = [
        {
          id           = "r-abcd1234"
          arn          = "arn:aws:organizations::123456789012:root/o-abcd1234/r-abcd1234"
          name         = "Root"
          policy_types = []
        }
      ]
    }
  }
}

############################################################
# enabled_policy_types default
############################################################

run "enabled_policy_types_defaults_to_service_control_policy" {
  command = plan

  assert {
    condition     = tolist(aws_organizations_organization.org.enabled_policy_types) == tolist(["SERVICE_CONTROL_POLICY"])
    error_message = "enabled_policy_types should default to [\"SERVICE_CONTROL_POLICY\"] so the SCPs enabled by default work out of the box without callers needing to set this explicitly."
  }
}

############################################################
# Deny Leave Organization Service Control Policy
############################################################

run "leave_organization_scp_enabled_by_default" {
  command = plan

  assert {
    condition     = length(module.leave_organization_scp) == 1
    error_message = "The Deny Leave Organization SCP should be created by default."
  }

  assert {
    condition     = length(aws_organizations_policy_attachment.leave_organization_scp) == 1
    error_message = "The Deny Leave Organization SCP should be attached to the organization root by default."
  }
}

run "leave_organization_scp_disabled_creates_no_resources" {
  command = plan

  variables {
    enable_leave_organization_scp = false
  }

  assert {
    condition     = length(module.leave_organization_scp) == 0
    error_message = "No Deny Leave Organization SCP should be created when disabled."
  }

  assert {
    condition     = length(aws_organizations_policy_attachment.leave_organization_scp) == 0
    error_message = "No Deny Leave Organization SCP attachment should be created when disabled."
  }
}

run "leave_organization_scp_requires_service_control_policy_type" {
  command = plan

  variables {
    enabled_policy_types       = ["TAG_POLICY"]
    enable_identity_center_scp = false
    enable_root_access_key_scp = false
  }

  expect_failures = [
    aws_organizations_policy_attachment.leave_organization_scp,
  ]
}

############################################################
# Deny Root Access Key Creation Service Control Policy
############################################################

run "root_access_key_scp_enabled_by_default" {
  command = plan

  assert {
    condition     = length(module.root_access_key_scp) == 1
    error_message = "The Deny Root Access Key Creation SCP should be created by default."
  }

  assert {
    condition     = length(aws_organizations_policy_attachment.root_access_key_scp) == 1
    error_message = "The Deny Root Access Key Creation SCP should be attached to the organization root by default."
  }
}

run "root_access_key_scp_disabled_creates_no_resources" {
  command = plan

  variables {
    enable_root_access_key_scp = false
  }

  assert {
    condition     = length(module.root_access_key_scp) == 0
    error_message = "No Deny Root Access Key Creation SCP should be created when disabled."
  }

  assert {
    condition     = length(aws_organizations_policy_attachment.root_access_key_scp) == 0
    error_message = "No Deny Root Access Key Creation SCP attachment should be created when disabled."
  }
}

run "root_access_key_scp_requires_service_control_policy_type" {
  command = plan

  variables {
    enabled_policy_types          = ["TAG_POLICY"]
    enable_identity_center_scp    = false
    enable_leave_organization_scp = false
  }

  expect_failures = [
    aws_organizations_policy_attachment.root_access_key_scp,
  ]
}

############################################################
# Deny Security Service Tampering Service Control Policy
############################################################

run "security_services_scp_disabled_by_default" {
  command = plan

  assert {
    condition     = length(module.security_services_scp) == 0
    error_message = "The Deny Security Service Tampering SCP should not be created by default (opt-in)."
  }
}

run "security_services_scp_enabled_creates_resources" {
  command = plan

  variables {
    enable_security_services_scp = true
  }

  assert {
    condition     = length(module.security_services_scp) == 1
    error_message = "The Deny Security Service Tampering SCP should be created when enabled."
  }

  assert {
    condition     = length(aws_organizations_policy_attachment.security_services_scp) == 1
    error_message = "The Deny Security Service Tampering SCP should be attached to the organization root by default."
  }
}

run "security_services_scp_requires_service_control_policy_type" {
  command = plan

  variables {
    enabled_policy_types          = ["TAG_POLICY"]
    enable_identity_center_scp    = false
    enable_leave_organization_scp = false
    enable_root_access_key_scp    = false
    enable_security_services_scp  = true
  }

  expect_failures = [
    aws_organizations_policy_attachment.security_services_scp,
  ]
}

run "security_services_scp_exempted_principal_arns_adds_arnnotlike_condition" {
  command = plan

  variables {
    enable_security_services_scp = true
    security_services_scp_exempted_principal_arns = [
      "arn:aws:iam::*:role/DelegatedSecurityAdminRole",
    ]
  }

  assert {
    condition     = strcontains(local.security_services_scp_content, "ArnNotLike")
    error_message = "The generated policy content should include an ArnNotLike condition when security_services_scp_exempted_principal_arns is non-empty."
  }

  assert {
    condition     = strcontains(local.security_services_scp_content, "arn:aws:iam::*:role/DelegatedSecurityAdminRole")
    error_message = "The generated policy content should include the supplied exempted principal ARN."
  }
}

run "security_services_scp_no_exempted_principal_arns_omits_arnnotlike_condition" {
  command = plan

  variables {
    enable_security_services_scp = true
  }

  assert {
    condition     = !strcontains(local.security_services_scp_content, "ArnNotLike")
    error_message = "The generated policy content should not include an ArnNotLike condition when no exempted principal ARNs are supplied."
  }
}

############################################################
# Deny Root User Actions Service Control Policy
############################################################

run "root_actions_scp_disabled_by_default" {
  command = plan

  assert {
    condition     = length(module.root_actions_scp) == 0
    error_message = "The Deny Root User Actions SCP should not be created by default (opt-in)."
  }
}

run "root_actions_scp_enabled_creates_resources" {
  command = plan

  variables {
    enable_root_actions_scp = true
  }

  assert {
    condition     = length(module.root_actions_scp) == 1
    error_message = "The Deny Root User Actions SCP should be created when enabled."
  }

  assert {
    condition     = length(aws_organizations_policy_attachment.root_actions_scp) == 1
    error_message = "The Deny Root User Actions SCP should be attached to the organization root by default."
  }
}

run "root_actions_scp_requires_service_control_policy_type" {
  command = plan

  variables {
    enabled_policy_types          = ["TAG_POLICY"]
    enable_identity_center_scp    = false
    enable_leave_organization_scp = false
    enable_root_access_key_scp    = false
    enable_root_actions_scp       = true
  }

  expect_failures = [
    aws_organizations_policy_attachment.root_actions_scp,
  ]
}

run "root_actions_scp_exempted_actions_merges_into_not_action" {
  command = plan

  variables {
    enable_root_actions_scp           = true
    root_actions_scp_exempted_actions = ["support:CreateCase"]
  }

  assert {
    condition     = strcontains(local.root_actions_scp_content, "support:CreateCase")
    error_message = "The generated policy's NotAction list should include caller-supplied root_actions_scp_exempted_actions entries."
  }

  assert {
    condition     = strcontains(local.root_actions_scp_content, "s3:PutBucketPolicy")
    error_message = "The generated policy's NotAction list should still include the built-in exemptions when caller-supplied actions are merged in."
  }
}
