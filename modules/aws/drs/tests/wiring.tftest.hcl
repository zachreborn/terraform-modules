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

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:us-east-1:123456789012:key/mocked-key"
      key_id = "mocked-key"
    }
  }

  mock_resource "aws_drs_replication_configuration_template" {
    defaults = {
      id  = "dtpl-abcd1234"
      arn = "arn:aws:drs:us-east-1:123456789012:replication-configuration-template/dtpl-abcd1234"
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
      arn = "arn:aws:iam::123456789012:role/aws-service-role/drs.amazonaws.com/AWSServiceRoleForElasticDisasterRecovery"
    }
  }
}

variables {
  templates = {
    app1 = {
      replication_servers_security_groups_ids = ["sg-abcd1234"]
      staging_area_subnet_id                  = "subnet-abcd1234"
    }
  }
}

run "created_kms_key_arn_reaches_every_template_by_default" {
  command = plan

  assert {
    condition     = output.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/mocked-key"
    error_message = "kms_key_arn output should expose the ARN of the KMS key this module creates by default."
  }

  assert {
    condition     = module.replication_configuration_template.templates["app1"].ebs_encryption == "CUSTOM"
    error_message = "Templates should resolve to CUSTOM encryption automatically when this module creates a KMS key."
  }

  assert {
    condition     = module.replication_configuration_template.templates["app1"].ebs_encryption_key_arn == "arn:aws:kms:us-east-1:123456789012:key/mocked-key"
    error_message = "The created KMS key's ARN should be injected into every template that did not set its own ebs_encryption_key_arn."
  }
}

run "create_kms_key_false_falls_back_to_default_encryption" {
  command = plan

  variables {
    create_kms_key = false
  }

  assert {
    condition     = output.kms_key_arn == null
    error_message = "kms_key_arn output should be null when create_kms_key is false and no kms_key_arn is supplied."
  }

  assert {
    condition     = module.replication_configuration_template.templates["app1"].ebs_encryption == "DEFAULT"
    error_message = "Templates should fall back to DEFAULT (AWS-managed) encryption when no customer managed key is available."
  }
}

run "existing_kms_key_arn_is_passed_through_without_creating_one" {
  command = plan

  variables {
    create_kms_key = false
    kms_key_arn    = "arn:aws:kms:us-east-1:123456789012:key/caller-supplied-key"
  }

  assert {
    condition     = output.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/caller-supplied-key"
    error_message = "kms_key_arn output should pass through the supplied existing kms_key_arn."
  }

  assert {
    condition     = module.replication_configuration_template.templates["app1"].ebs_encryption == "CUSTOM"
    error_message = "Templates should resolve to CUSTOM encryption when an existing kms_key_arn is supplied, even without creating a new key."
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No KMS key should be created when create_kms_key is false, even if kms_key_arn is supplied."
  }
}

run "create_kms_key_and_kms_key_arn_are_mutually_exclusive" {
  command = plan

  variables {
    create_kms_key = true
    kms_key_arn    = "arn:aws:kms:us-east-1:123456789012:key/caller-supplied-key"
  }

  expect_failures = [
    terraform_data.validate_kms_inputs,
  ]
}

run "initialization_is_created_but_creates_no_roles_by_default" {
  command = plan

  assert {
    condition     = length(module.initialization) == 1
    error_message = "The initialization submodule should be created by default (create_initialization defaults to true)."
  }

  assert {
    condition     = length(output.initialization_role_arns) == 0
    error_message = "No service roles should be created by default, since create_service_roles defaults to false at the wrapper level."
  }

  assert {
    condition     = output.initialization_service_linked_role_arn == null
    error_message = "No service-linked role should be created by default, since create_service_linked_role defaults to false at the wrapper level."
  }
}

run "create_service_roles_true_creates_all_six_roles_through_the_wrapper" {
  command = plan

  variables {
    create_service_roles       = true
    create_service_linked_role = true
  }

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
      contains(keys(output.initialization_role_arns), role_name)
    ])
    error_message = "Flipping create_service_roles on through the wrapper should create all six documented service roles."
  }

  assert {
    condition     = output.initialization_service_linked_role_arn != null
    error_message = "Flipping create_service_linked_role on through the wrapper should create the service-linked role."
  }
}

run "create_initialization_false_skips_the_submodule_entirely" {
  command = plan

  variables {
    create_initialization = false
  }

  assert {
    condition     = length(module.initialization) == 0
    error_message = "The initialization submodule should not be instantiated at all when create_initialization is false."
  }

  assert {
    condition     = length(output.initialization_role_arns) == 0
    error_message = "initialization_role_arns output should be empty when create_initialization is false."
  }
}

run "per_template_key_survives_without_a_global_key" {
  command = plan

  variables {
    create_kms_key = false
    templates = {
      app1 = {
        ebs_encryption_key_arn                  = "arn:aws:kms:us-east-1:123456789012:key/caller-template-key"
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
      }
    }
  }

  assert {
    condition     = module.replication_configuration_template.templates["app1"].ebs_encryption == "CUSTOM"
    error_message = "A template's own ebs_encryption_key_arn should resolve to CUSTOM even when this module has no shared key of its own."
  }

  assert {
    condition     = module.replication_configuration_template.templates["app1"].ebs_encryption_key_arn == "arn:aws:kms:us-east-1:123456789012:key/caller-template-key"
    error_message = "A template's own ebs_encryption_key_arn should be passed through unchanged."
  }
}

run "cross_region_template_without_its_own_key_is_rejected" {
  command = plan

  variables {
    templates = {
      app1 = {
        region                                  = "us-west-2"
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
      }
    }
  }

  expect_failures = [
    terraform_data.validate_kms_inputs,
  ]
}

run "cross_region_template_with_its_own_key_is_allowed" {
  command = plan

  variables {
    templates = {
      app1 = {
        ebs_encryption_key_arn                  = "arn:aws:kms:us-west-2:123456789012:key/region-specific-key"
        region                                  = "us-west-2"
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
      }
    }
  }

  assert {
    condition     = module.replication_configuration_template.templates["app1"].ebs_encryption_key_arn == "arn:aws:kms:us-west-2:123456789012:key/region-specific-key"
    error_message = "A cross-region template that supplies its own same-region key should not trip the cross-region guard."
  }
}

run "remaining_outputs_are_asserted" {
  command = plan

  variables {
    create_service_roles       = true
    create_service_linked_role = true
  }

  assert {
    condition     = output.replication_configuration_template_arns["app1"] != null
    error_message = "replication_configuration_template_arns output should expose each template's ARN."
  }

  assert {
    condition     = output.replication_configuration_template_ids["app1"] != null
    error_message = "replication_configuration_template_ids output should expose each template's ID."
  }

  assert {
    condition     = output.initialization_role_names["AWSElasticDisasterRecoveryAgentRole"] != null
    error_message = "initialization_role_names output should expose the agent role's name."
  }

  assert {
    condition     = length(output.initialization_instance_profile_arns) == 4
    error_message = "initialization_instance_profile_arns output should expose an ARN for each of the four EC2-assumed roles."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
