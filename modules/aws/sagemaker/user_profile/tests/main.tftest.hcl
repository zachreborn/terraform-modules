mock_provider "aws" {
  mock_resource "aws_sagemaker_user_profile" {
    defaults = {
      id                       = "arn:aws:sagemaker:us-east-1:123456789012:user-profile/d-0123456789ab/data-scientist-jane"
      arn                      = "arn:aws:sagemaker:us-east-1:123456789012:user-profile/d-0123456789ab/data-scientist-jane"
      home_efs_file_system_uid = "1000"
    }
  }
}

# Note: user_profile_name is a plain (non-computed) required argument that is always known
# from configuration, so it intentionally has no fixed mock default here -- OpenTofu rejects
# mock defaults for non-computed fields. output.user_profile_name is asserted below by
# comparing it to the resource's own attribute rather than a fixed mock literal.

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    domain_id         = "d-0123456789ab"
    user_profile_name = "data-scientist-jane"
    user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    }
  }

  assert {
    condition     = length(aws_sagemaker_user_profile.this.user_settings) == 1
    error_message = "user_settings should always emit exactly one block, since it is a required argument."
  }

  assert {
    condition     = aws_sagemaker_user_profile.this.user_settings[0].execution_role == "arn:aws:iam::123456789012:role/sagemaker-execution-role"
    error_message = "user_settings.execution_role should be wired through."
  }

  assert {
    condition     = aws_sagemaker_user_profile.this.tags["Name"] == "data-scientist-jane"
    error_message = "tags should default to include Name = var.user_profile_name."
  }

  assert {
    condition     = aws_sagemaker_user_profile.this.single_sign_on_user_identifier == null
    error_message = "single_sign_on_user_identifier should default to null for IAM domains."
  }

  assert {
    condition     = aws_sagemaker_user_profile.this.single_sign_on_user_value == null
    error_message = "single_sign_on_user_value should default to null for IAM domains."
  }

  assert {
    condition     = output.id == "arn:aws:sagemaker:us-east-1:123456789012:user-profile/d-0123456789ab/data-scientist-jane"
    error_message = "id output should expose the mocked resource id."
  }

  assert {
    condition     = output.arn == "arn:aws:sagemaker:us-east-1:123456789012:user-profile/d-0123456789ab/data-scientist-jane"
    error_message = "arn output should expose the mocked resource arn."
  }

  assert {
    condition     = output.user_profile_name == aws_sagemaker_user_profile.this.user_profile_name
    error_message = "user_profile_name output should expose the resource's user_profile_name attribute."
  }

  assert {
    condition     = output.home_efs_file_system_uid == "1000"
    error_message = "home_efs_file_system_uid output should expose the mocked value."
  }
}

run "sso_fields_are_honored" {
  command = plan

  variables {
    domain_id                      = "d-0123456789ab"
    user_profile_name              = "jane-doe"
    single_sign_on_user_identifier = "UserName"
    single_sign_on_user_value      = "jane.doe"
    user_settings = {
      execution_role = "arn:aws:iam::123456789012:role/sagemaker-execution-role"

      jupyter_lab_app_settings = {
        default_resource_spec = {
          instance_type = "ml.t3.medium"
        }
      }
    }
  }

  assert {
    condition     = aws_sagemaker_user_profile.this.single_sign_on_user_identifier == "UserName"
    error_message = "single_sign_on_user_identifier override should be honored."
  }

  assert {
    condition     = aws_sagemaker_user_profile.this.single_sign_on_user_value == "jane.doe"
    error_message = "single_sign_on_user_value override should be honored."
  }

  assert {
    condition     = aws_sagemaker_user_profile.this.user_settings[0].jupyter_lab_app_settings[0].default_resource_spec[0].instance_type == "ml.t3.medium"
    error_message = "user_settings.jupyter_lab_app_settings.default_resource_spec.instance_type should be wired through."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
