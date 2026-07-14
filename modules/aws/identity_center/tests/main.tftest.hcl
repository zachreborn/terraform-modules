mock_provider "aws" {
  mock_data "aws_ssoadmin_instances" {
    defaults = {
      identity_store_ids = ["d-1234567890"]
      arns               = ["arn:aws:sso:::instance/ssoins-1234567890abcdef"]
    }
  }
}

run "valid_baseline_plans_successfully" {
  command = plan

  variables {
    groups = {
      Administrators = {
        display_name = "Administrators"
        description  = "The group for the administrators of the application."
      }
    }
    users = {
      "John Hill" = {
        given_name  = "John"
        family_name = "Hill"
        user_name   = "john.hill@example.com"
        email       = "john.hill@example.com"
        groups      = ["Administrators"]
      }
    }
  }

  assert {
    condition     = aws_identitystore_user.this["John Hill"].identity_store_id == "d-1234567890"
    error_message = "identity_store_id should resolve from the aws_ssoadmin_instances data source."
  }

  assert {
    condition     = aws_identitystore_user.this["John Hill"].name[0].given_name == "John"
    error_message = "name.given_name should pass through unchanged."
  }

  assert {
    condition     = aws_identitystore_user.this["John Hill"].name[0].family_name == "Hill"
    error_message = "name.family_name should pass through unchanged."
  }

  assert {
    condition     = aws_identitystore_user.this["John Hill"].emails[0].value == "john.hill@example.com"
    error_message = "emails.value should pass through unchanged."
  }

  assert {
    condition     = aws_identitystore_group.this["Administrators"].display_name == "Administrators"
    error_message = "display_name should pass through unchanged."
  }

  assert {
    condition     = aws_identitystore_group.this["Administrators"].description == "The group for the administrators of the application."
    error_message = "description should pass through unchanged."
  }

  assert {
    condition     = length(aws_identitystore_group_membership.this) == 1
    error_message = "Expected exactly one group membership derived from John Hill's groups list."
  }

  assert {
    condition     = contains(keys(aws_identitystore_group_membership.this), "John Hill-Administrators")
    error_message = "Group membership should be keyed as '<user_display_name>-<group_name>'."
  }

  assert {
    condition     = output.user_ids["John Hill"] == aws_identitystore_user.this["John Hill"].id
    error_message = "user_ids output should forward the exact id of the corresponding user resource."
  }

  assert {
    condition     = output.group_ids["Administrators"] == aws_identitystore_group.this["Administrators"].id
    error_message = "group_ids output should forward the exact id of the corresponding group resource."
  }

  assert {
    condition     = output.group_memberships["John Hill-Administrators"].membership_id == aws_identitystore_group_membership.this["John Hill-Administrators"].membership_id
    error_message = "group_memberships.membership_id should forward the exact membership_id of the corresponding membership resource."
  }

  assert {
    condition     = output.group_memberships["John Hill-Administrators"].member == aws_identitystore_user.this["John Hill"].user_id
    error_message = "group_memberships.member should forward the exact user_id of the member, proving the output is wired to the underlying user resource."
  }

  assert {
    condition     = output.group_memberships["John Hill-Administrators"].group == aws_identitystore_group.this["Administrators"].group_id
    error_message = "group_memberships.group should forward the exact group_id, proving the output is wired to the underlying group resource."
  }
}

run "empty_users_and_groups_create_nothing" {
  command = plan

  variables {
    groups = {}
    users  = {}
  }

  assert {
    condition     = length(aws_identitystore_user.this) == 0
    error_message = "Expected no users to be planned when var.users is empty."
  }

  assert {
    condition     = length(aws_identitystore_group.this) == 0
    error_message = "Expected no groups to be planned when var.groups is empty."
  }

  assert {
    condition     = length(aws_identitystore_group_membership.this) == 0
    error_message = "Expected no group memberships to be planned when there are no users or groups."
  }
}

run "user_with_no_groups_creates_no_membership" {
  command = plan

  variables {
    groups = {}
    users = {
      "Jane Doe" = {
        given_name  = "Jane"
        family_name = "Doe"
        user_name   = "jane.doe@example.com"
      }
    }
  }

  assert {
    condition     = length(aws_identitystore_group_membership.this) == 0
    error_message = "Expected no group memberships when the user's groups list is unset."
  }
}

run "user_in_multiple_groups_creates_one_membership_each" {
  command = plan

  variables {
    groups = {
      Administrators = {
        display_name = "Administrators"
      }
      Users = {
        display_name = "Users"
      }
    }
    users = {
      "John Hill" = {
        given_name  = "John"
        family_name = "Hill"
        user_name   = "john.hill@example.com"
        groups      = ["Administrators", "Users"]
      }
    }
  }

  assert {
    condition     = length(aws_identitystore_group_membership.this) == 2
    error_message = "Expected one membership per group the user belongs to."
  }

  assert {
    condition     = contains(keys(aws_identitystore_group_membership.this), "John Hill-Administrators")
    error_message = "Expected a membership key for the Administrators group."
  }

  assert {
    condition     = contains(keys(aws_identitystore_group_membership.this), "John Hill-Users")
    error_message = "Expected a membership key for the Users group."
  }
}

run "optional_user_fields_pass_through" {
  command = plan

  variables {
    groups = {}
    users = {
      "John Hill" = {
        given_name              = "John"
        family_name             = "Hill"
        user_name               = "john.hill@example.com"
        honorific_prefix        = "Mr."
        middle_name             = "Q"
        nickname                = "Johnny"
        email                   = "john.hill@example.com"
        email_is_primary        = true
        email_type              = "work"
        phone_number            = "+15555550100"
        phone_number_is_primary = true
        phone_number_type       = "work"
        preferred_language      = "en"
        timezone                = "America/New_York"
        title                   = "Engineer"
        user_type               = "employee"
      }
    }
  }

  assert {
    condition     = aws_identitystore_user.this["John Hill"].name[0].honorific_prefix == "Mr."
    error_message = "honorific_prefix should pass through unchanged."
  }

  assert {
    condition     = aws_identitystore_user.this["John Hill"].emails[0].primary == true
    error_message = "emails.primary should pass through unchanged."
  }

  assert {
    condition     = aws_identitystore_user.this["John Hill"].phone_numbers[0].value == "+15555550100"
    error_message = "phone_numbers.value should pass through unchanged."
  }

  assert {
    condition     = aws_identitystore_user.this["John Hill"].timezone == "America/New_York"
    error_message = "timezone should pass through unchanged."
  }

  assert {
    condition     = aws_identitystore_user.this["John Hill"].title == "Engineer"
    error_message = "title should pass through unchanged."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that the module code has a bug and fix the root cause in main.tf / variables.tf /
# outputs.tf, then re-run `tofu test` until it passes for the right reason.
