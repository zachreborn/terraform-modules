mock_provider "aws" {
  mock_resource "aws_iam_instance_profile" {
    defaults = {
      arn         = "arn:aws:iam::123456789012:instance-profile/mock-profile"
      id          = "mock-profile"
      unique_id   = "AIPAMOCKUNIQUEID12345"
      create_date = "2026-01-01T00:00:00Z"
    }
  }
}

variables {
  name = "example-profile"
  role = "example-role"
}

run "valid_baseline_does_not_fail" {
  command = plan

  assert {
    condition     = aws_iam_instance_profile.this.role == "example-role"
    error_message = "Valid baseline inputs must not fail validation."
  }
}

run "rejects_empty_role" {
  command = plan

  variables {
    role = ""
  }

  expect_failures = [var.role]
}

run "rejects_role_arn" {
  command = plan

  variables {
    role = "arn:aws:iam::123456789012:role/example"
  }

  expect_failures = [var.role]
}

run "rejects_role_with_invalid_characters" {
  command = plan

  variables {
    role = "bad/role name"
  }

  expect_failures = [var.role]
}

run "rejects_role_longer_than_64_characters" {
  command = plan

  variables {
    role = join("", [for i in range(65) : "a"])
  }

  expect_failures = [var.role]
}

run "rejects_name_with_invalid_characters" {
  command = plan

  variables {
    name = "bad name!"
  }

  expect_failures = [var.name]
}

run "rejects_name_longer_than_128_characters" {
  command = plan

  variables {
    name = join("", [for i in range(129) : "a"])
  }

  expect_failures = [var.name]
}

run "rejects_name_prefix_with_invalid_characters" {
  command = plan

  variables {
    name        = null
    name_prefix = "bad prefix!"
  }

  expect_failures = [var.name_prefix]
}

run "rejects_name_prefix_longer_than_102_characters" {
  command = plan

  variables {
    name        = null
    name_prefix = join("", [for i in range(103) : "a"])
  }

  expect_failures = [var.name_prefix]
}

run "rejects_path_without_leading_and_trailing_slash" {
  command = plan

  variables {
    path = "service-role"
  }

  expect_failures = [var.path]
}

run "rejects_path_longer_than_512_characters" {
  command = plan

  variables {
    path = "/${join("", [for i in range(511) : "a"])}/"
  }

  expect_failures = [var.path]
}

run "rejects_both_name_and_name_prefix" {
  command = plan

  variables {
    name_prefix = "example-"
  }

  expect_failures = [aws_iam_instance_profile.this]
}

run "rejects_empty_name" {
  command = plan

  variables {
    name = ""
  }

  expect_failures = [var.name]
}

run "rejects_empty_name_prefix" {
  command = plan

  variables {
    name        = null
    name_prefix = ""
  }

  expect_failures = [var.name_prefix]
}

run "rejects_role_with_path" {
  command = plan

  variables {
    role = "/service/my-role"
  }

  expect_failures = [var.role]
}

run "rejects_path_without_leading_slash" {
  command = plan

  variables {
    path = "service-role/"
  }

  expect_failures = [var.path]
}

run "rejects_path_without_trailing_slash" {
  command = plan

  variables {
    path = "/service-role"
  }

  expect_failures = [var.path]
}

run "accepts_maximum_name_role_and_path_lengths" {
  command = plan

  variables {
    name = join("", [for i in range(128) : "a"])
    role = join("", [for i in range(64) : "b"])
    path = "/${join("", [for i in range(510) : "c"])}/"
  }

  assert {
    condition     = aws_iam_instance_profile.this.name == var.name && aws_iam_instance_profile.this.role == var.role && aws_iam_instance_profile.this.path == var.path
    error_message = "Names, roles, and paths at their exact maximum lengths must be accepted unchanged."
  }
}

run "accepts_maximum_prefix_length_and_iam_punctuation" {
  command = plan

  variables {
    name        = null
    name_prefix = "${join("", [for i in range(95) : "a"])}_+=,.@-"
    role        = "AbZ09_+=,.@-"
  }

  assert {
    condition     = aws_iam_instance_profile.this.name_prefix == var.name_prefix && aws_iam_instance_profile.this.role == "AbZ09_+=,.@-"
    error_message = "A 102-character prefix and all allowed IAM name punctuation must be accepted unchanged."
  }
}

run "rejects_neither_name_nor_name_prefix" {
  command = plan

  variables {
    name = null
  }

  expect_failures = [aws_iam_instance_profile.this]
}
