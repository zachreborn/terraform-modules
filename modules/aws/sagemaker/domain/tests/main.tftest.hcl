mock_provider "aws" {
  mock_resource "aws_sagemaker_domain" {
    defaults = {
      id                                             = "d-0123456789ab"
      arn                                            = "arn:aws:sagemaker:us-east-1:123456789012:domain/d-0123456789ab"
      url                                            = "https://d-0123456789ab.studio.us-east-1.sagemaker.aws"
      home_efs_file_system_id                        = "fs-0123456789abcdef0"
      security_group_id_for_domain_boundary          = "sg-0123456789abcdef0"
      single_sign_on_managed_application_instance_id = "apl-0123456789abcdef"
      single_sign_on_application_arn                 = "arn:aws:sso::123456789012:application/apl-0123456789abcdef"
    }
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    domain_name = "ml-platform"
    auth_mode   = "IAM"
    vpc_id      = "vpc-0123456789abcdef0"
    subnet_ids  = ["subnet-0123456789abcdef0"]
    default_user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
  }

  assert {
    condition     = aws_sagemaker_domain.this.app_network_access_type == "VpcOnly"
    error_message = "app_network_access_type should default to VpcOnly for a secure-by-default posture."
  }

  assert {
    condition     = aws_sagemaker_domain.this.tag_propagation == "DISABLED"
    error_message = "tag_propagation should default to DISABLED."
  }

  assert {
    condition     = aws_sagemaker_domain.this.tags["Name"] == "ml-platform"
    error_message = "tags should default to include Name = var.domain_name."
  }

  assert {
    condition     = aws_sagemaker_domain.this.default_user_settings[0].execution_role == "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    error_message = "default_user_settings.execution_role should be wired through."
  }

  assert {
    condition     = length(aws_sagemaker_domain.this.default_space_settings) == 0
    error_message = "default_space_settings should default to no blocks when unset."
  }

  assert {
    condition     = length(aws_sagemaker_domain.this.domain_settings) == 0
    error_message = "domain_settings should default to no blocks when unset."
  }

  assert {
    condition     = length(aws_sagemaker_domain.this.retention_policy) == 0
    error_message = "retention_policy should default to no blocks when unset."
  }

  assert {
    condition     = output.id == "d-0123456789ab"
    error_message = "id output should expose the mocked domain id."
  }

  assert {
    condition     = output.arn == "arn:aws:sagemaker:us-east-1:123456789012:domain/d-0123456789ab"
    error_message = "arn output should expose the mocked domain arn."
  }

  assert {
    condition     = output.url == "https://d-0123456789ab.studio.us-east-1.sagemaker.aws"
    error_message = "url output should expose the mocked domain url."
  }

  assert {
    condition     = output.home_efs_file_system_id == "fs-0123456789abcdef0"
    error_message = "home_efs_file_system_id output should expose the mocked value."
  }
}

run "overrides_are_honored" {
  command = plan

  variables {
    domain_name                   = "data-science"
    auth_mode                     = "IAM"
    vpc_id                        = "vpc-0123456789abcdef0"
    subnet_ids                    = ["subnet-0123456789abcdef0"]
    app_network_access_type       = "VpcOnly"
    app_security_group_management = "Service"
    tag_propagation               = "ENABLED"
    default_user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
    default_space_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-space-role"
    }
    domain_settings = {
      execution_role_identity_config = "USER_PROFILE_NAME"
    }
    retention_policy = {
      home_efs_file_system = "Retain"
    }
    tags = {
      team = "platform"
    }
  }

  assert {
    condition     = aws_sagemaker_domain.this.app_security_group_management == "Service"
    error_message = "app_security_group_management override should be honored."
  }

  assert {
    condition     = aws_sagemaker_domain.this.tag_propagation == "ENABLED"
    error_message = "tag_propagation override should be honored."
  }

  assert {
    condition     = length(aws_sagemaker_domain.this.default_space_settings) == 1
    error_message = "default_space_settings should emit exactly one block when set."
  }

  assert {
    condition     = aws_sagemaker_domain.this.default_space_settings[0].execution_role == "arn:aws:iam::123456789012:role/sagemaker-space-role"
    error_message = "default_space_settings.execution_role should be wired through."
  }

  assert {
    condition     = length(aws_sagemaker_domain.this.domain_settings) == 1
    error_message = "domain_settings should emit exactly one block when set."
  }

  assert {
    condition     = aws_sagemaker_domain.this.domain_settings[0].execution_role_identity_config == "USER_PROFILE_NAME"
    error_message = "domain_settings.execution_role_identity_config should be wired through."
  }

  assert {
    condition     = length(aws_sagemaker_domain.this.retention_policy) == 1
    error_message = "retention_policy should emit exactly one block when set."
  }

  assert {
    condition     = aws_sagemaker_domain.this.retention_policy[0].home_efs_file_system == "Retain"
    error_message = "retention_policy.home_efs_file_system should be wired through."
  }

  assert {
    condition     = aws_sagemaker_domain.this.tags["team"] == "platform"
    error_message = "Custom tags should be merged into the domain tags."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
