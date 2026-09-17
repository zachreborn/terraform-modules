mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mocked-role"
    }
  }

  mock_resource "aws_iam_instance_profile" {
    defaults = {
      arn = "arn:aws:iam::123456789012:instance-profile/mocked-instance-profile"
    }
  }

  mock_resource "aws_iam_service_linked_role" {
    defaults = {
      arn  = "arn:aws:iam::123456789012:role/aws-service-role/drs.amazonaws.com/AWSServiceRoleForElasticDisasterRecovery"
      name = "AWSServiceRoleForElasticDisasterRecovery"
    }
  }
}

run "baseline_creates_all_six_service_roles_and_the_service_linked_role" {
  command = plan

  assert {
    condition = alltrue([
      for role_name in [
        "AWSElasticDisasterRecoveryAgentRole",
        "AWSElasticDisasterRecoveryFailbackRole",
        "AWSElasticDisasterRecoveryConversionServerRole",
        "AWSElasticDisasterRecoveryRecoveryInstanceRole",
        "AWSElasticDisasterRecoveryRecoveryInstanceWithLaunchActionsRole",
        "AWSElasticDisasterRecoveryReplicationServerRole",
      ] :
      contains(keys(module.role), role_name)
    ])
    error_message = "Expected all six documented Elastic Disaster Recovery service roles to be created by default."
  }

  assert {
    condition     = length(aws_iam_service_linked_role.this) == 1
    error_message = "Expected the AWSServiceRoleForElasticDisasterRecovery service-linked role to be created by default."
  }

  assert {
    condition     = output.service_linked_role_arn != null
    error_message = "service_linked_role_arn output should expose the mocked service-linked role ARN."
  }
}

run "agent_and_failback_roles_trust_drs_with_source_identity_condition" {
  command = plan

  assert {
    condition     = strcontains(module.role["AWSElasticDisasterRecoveryAgentRole"].name, "AWSElasticDisasterRecoveryAgentRole")
    error_message = "The agent role's name should match the documented role name."
  }

  assert {
    condition = strcontains(
      local.drs_assume_role_policies["AWSElasticDisasterRecoveryAgentRole"],
      "sts:SetSourceIdentity"
    )
    error_message = "The agent role's trust policy must include sts:SetSourceIdentity, the documented confused-deputy guard."
  }

  assert {
    condition = strcontains(
      local.drs_assume_role_policies["AWSElasticDisasterRecoveryAgentRole"],
      "s-*"
    )
    error_message = "The agent role's trust policy must scope sts:SourceIdentity to source-server IDs (s-*)."
  }

  assert {
    condition = strcontains(
      local.drs_assume_role_policies["AWSElasticDisasterRecoveryFailbackRole"],
      "i-*"
    )
    error_message = "The failback role's trust policy must scope sts:SourceIdentity to recovery-instance IDs (i-*)."
  }

  assert {
    condition = strcontains(
      local.drs_assume_role_policies["AWSElasticDisasterRecoveryAgentRole"],
      "123456789012"
    )
    error_message = "The agent role's trust policy must scope aws:SourceAccount to the calling account."
  }
}

run "ec2_assumed_roles_get_an_instance_profile" {
  command = plan

  assert {
    condition = alltrue([
      for role_name in [
        "AWSElasticDisasterRecoveryConversionServerRole",
        "AWSElasticDisasterRecoveryRecoveryInstanceRole",
        "AWSElasticDisasterRecoveryRecoveryInstanceWithLaunchActionsRole",
        "AWSElasticDisasterRecoveryReplicationServerRole",
      ] :
      contains(keys(aws_iam_instance_profile.this), role_name)
    ])
    error_message = "Expected an instance profile for every EC2-assumed Elastic Disaster Recovery role."
  }

  assert {
    condition = alltrue([
      for role_name in [
        "AWSElasticDisasterRecoveryAgentRole",
        "AWSElasticDisasterRecoveryFailbackRole",
      ] :
      !contains(keys(aws_iam_instance_profile.this), role_name)
    ])
    error_message = "The DRS-assumed agent and failback roles must not get an instance profile."
  }
}

run "launch_actions_role_gets_ssm_managed_instance_core" {
  command = plan

  assert {
    condition = contains(
      local.roles["AWSElasticDisasterRecoveryRecoveryInstanceWithLaunchActionsRole"].policy_arns,
      "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    )
    error_message = "The launch-actions role must be attached to AmazonSSMManagedInstanceCore in addition to its DRS policy."
  }
}

run "create_service_roles_false_creates_nothing" {
  command = plan

  variables {
    create_service_roles       = false
    create_service_linked_role = false
  }

  assert {
    condition     = length(module.role) == 0
    error_message = "No service roles should be created when create_service_roles is false."
  }

  assert {
    condition     = length(aws_iam_instance_profile.this) == 0
    error_message = "No instance profiles should be created when create_service_roles is false."
  }

  assert {
    condition     = length(aws_iam_service_linked_role.this) == 0
    error_message = "No service-linked role should be created when create_service_linked_role is false."
  }

  assert {
    condition     = output.service_linked_role_arn == null
    error_message = "service_linked_role_arn output should be null when create_service_linked_role is false."
  }
}

run "additional_policy_arns_are_merged_onto_the_named_role" {
  command = plan

  variables {
    additional_policy_arns = {
      AWSElasticDisasterRecoveryAgentRole = ["arn:aws:iam::123456789012:policy/extra-agent-policy"]
    }
  }

  assert {
    condition = contains(
      local.effective_policy_arns["AWSElasticDisasterRecoveryAgentRole"],
      "arn:aws:iam::123456789012:policy/extra-agent-policy"
    )
    error_message = "additional_policy_arns entries should be merged onto the named role's effective policy_arns."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
