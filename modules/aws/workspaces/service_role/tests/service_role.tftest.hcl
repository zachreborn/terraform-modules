mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

run "valid_baseline_creates_role_with_default_name" {
  command = plan

  assert {
    condition     = output.name == "workspaces_DefaultRole"
    error_message = "name should default to workspaces_DefaultRole."
  }

  assert {
    condition     = output.arn != null
    error_message = "arn output should be non-null."
  }
}

run "self_service_access_enabled_by_default" {
  command = plan

  assert {
    condition     = length(output.policy_arns) == 2
    error_message = "Both managed policies should be attached by default, matching AWS's own default workspaces_DefaultRole setup."
  }

  assert {
    condition     = contains(output.policy_arns, "arn:aws:iam::aws:policy/AmazonWorkSpacesServiceAccess")
    error_message = "AmazonWorkSpacesServiceAccess should always be attached."
  }

  assert {
    condition     = contains(output.policy_arns, "arn:aws:iam::aws:policy/AmazonWorkSpacesSelfServiceAccess")
    error_message = "AmazonWorkSpacesSelfServiceAccess should be attached by default."
  }
}

run "disabling_self_service_access_attaches_only_one_policy" {
  command = plan

  variables {
    enable_self_service_access = false
  }

  assert {
    condition     = length(output.policy_arns) == 1
    error_message = "Only the service-access policy should be attached when enable_self_service_access is false."
  }

  assert {
    condition     = contains(output.policy_arns, "arn:aws:iam::aws:policy/AmazonWorkSpacesServiceAccess")
    error_message = "AmazonWorkSpacesServiceAccess should always be attached."
  }
}

run "rejects_name_override" {
  command = plan

  variables {
    name = "custom_workspaces_role"
  }

  expect_failures = [var.name]
}
