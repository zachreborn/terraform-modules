mock_provider "aws" {
  mock_resource "aws_drs_replication_configuration_template" {
    defaults = {
      id  = "dtpl-abcd1234"
      arn = "arn:aws:drs:us-east-1:123456789012:replication-configuration-template/dtpl-abcd1234"
    }
  }
}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    templates = {
      app1 = {
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
      }
    }
  }

  assert {
    condition     = output.arns["app1"] != null
    error_message = "A minimal, valid template should plan successfully."
  }
}

run "rejects_invalid_data_plane_routing" {
  command = plan

  variables {
    templates = {
      app1 = {
        data_plane_routing                      = "INVALID"
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_invalid_default_large_staging_disk_type" {
  command = plan

  variables {
    templates = {
      app1 = {
        default_large_staging_disk_type         = "INVALID"
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_custom_encryption_without_key_arn" {
  command = plan

  variables {
    templates = {
      app1 = {
        ebs_encryption                          = "CUSTOM"
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_no_security_groups_without_default_security_group" {
  command = plan

  variables {
    templates = {
      app1 = {
        associate_default_security_group        = false
        replication_servers_security_groups_ids = []
        staging_area_subnet_id                  = "subnet-abcd1234"
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_negative_bandwidth_throttling" {
  command = plan

  variables {
    templates = {
      app1 = {
        bandwidth_throttling                    = -1
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_pit_policy_rule_1_mutation" {
  command = plan

  variables {
    templates = {
      app1 = {
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
        pit_policy = [
          {
            enabled            = true
            interval           = 5
            retention_duration = 60
            rule_id            = 1
            units              = "MINUTE"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 24
            rule_id            = 2
            units              = "HOUR"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 3
            rule_id            = 3
            units              = "DAY"
          },
        ]
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_pit_policy_rule_2_mutation" {
  command = plan

  variables {
    templates = {
      app1 = {
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
        pit_policy = [
          {
            enabled            = true
            interval           = 10
            retention_duration = 60
            rule_id            = 1
            units              = "MINUTE"
          },
          {
            enabled            = true
            interval           = 2
            retention_duration = 24
            rule_id            = 2
            units              = "HOUR"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 3
            rule_id            = 3
            units              = "DAY"
          },
        ]
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_pit_policy_rule_3_units_mutation" {
  command = plan

  variables {
    templates = {
      app1 = {
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
        pit_policy = [
          {
            enabled            = true
            interval           = 10
            retention_duration = 60
            rule_id            = 1
            units              = "MINUTE"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 24
            rule_id            = 2
            units              = "HOUR"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 3
            rule_id            = 3
            units              = "HOUR"
          },
        ]
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_invalid_ebs_encryption" {
  command = plan

  variables {
    templates = {
      app1 = {
        ebs_encryption                          = "BOGUS"
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_empty_pit_policy" {
  command = plan

  variables {
    templates = {
      app1 = {
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
        pit_policy                              = []
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_invalid_pit_policy_units" {
  command = plan

  variables {
    templates = {
      app1 = {
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
        pit_policy = [
          {
            enabled            = true
            interval           = 10
            retention_duration = 60
            rule_id            = 1
            units              = "SECOND"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 24
            rule_id            = 2
            units              = "HOUR"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 3
            rule_id            = 3
            units              = "DAY"
          },
        ]
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_pit_policy_missing_rule_3" {
  command = plan

  variables {
    templates = {
      app1 = {
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
        pit_policy = [
          {
            enabled            = true
            interval           = 10
            retention_duration = 60
            rule_id            = 1
            units              = "MINUTE"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 24
            rule_id            = 2
            units              = "HOUR"
          },
        ]
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_pit_policy_duplicate_rule_id" {
  command = plan

  variables {
    templates = {
      app1 = {
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
        pit_policy = [
          {
            enabled            = true
            interval           = 10
            retention_duration = 60
            rule_id            = 1
            units              = "MINUTE"
          },
          {
            enabled            = true
            interval           = 10
            retention_duration = 60
            rule_id            = 1
            units              = "MINUTE"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 3
            rule_id            = 3
            units              = "DAY"
          },
        ]
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_default_encryption_with_key_arn" {
  command = plan

  variables {
    templates = {
      app1 = {
        ebs_encryption                          = "DEFAULT"
        ebs_encryption_key_arn                  = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-1234-1234-1234-123456789012"
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_none_encryption_with_key_arn" {
  command = plan

  variables {
    templates = {
      app1 = {
        ebs_encryption                          = "NONE"
        ebs_encryption_key_arn                  = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-1234-1234-1234-123456789012"
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_disabled_pit_policy_rule" {
  command = plan

  variables {
    templates = {
      app1 = {
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
        pit_policy = [
          {
            enabled            = false
            interval           = 10
            retention_duration = 60
            rule_id            = 1
            units              = "MINUTE"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 24
            rule_id            = 2
            units              = "HOUR"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 3
            rule_id            = 3
            units              = "DAY"
          },
        ]
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_rule_3_retention_duration_below_minimum" {
  command = plan

  variables {
    templates = {
      app1 = {
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
        pit_policy = [
          {
            enabled            = true
            interval           = 10
            retention_duration = 60
            rule_id            = 1
            units              = "MINUTE"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 24
            rule_id            = 2
            units              = "HOUR"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 0
            rule_id            = 3
            units              = "DAY"
          },
        ]
      }
    }
  }

  expect_failures = [var.templates]
}

run "rejects_rule_3_retention_duration_above_maximum" {
  command = plan

  variables {
    templates = {
      app1 = {
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
        pit_policy = [
          {
            enabled            = true
            interval           = 10
            retention_duration = 60
            rule_id            = 1
            units              = "MINUTE"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 24
            rule_id            = 2
            units              = "HOUR"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 366
            rule_id            = 3
            units              = "DAY"
          },
        ]
      }
    }
  }

  expect_failures = [var.templates]
}

run "allows_rule_3_retention_duration_at_maximum" {
  command = plan

  variables {
    templates = {
      app1 = {
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
        pit_policy = [
          {
            enabled            = true
            interval           = 10
            retention_duration = 60
            rule_id            = 1
            units              = "MINUTE"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 24
            rule_id            = 2
            units              = "HOUR"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 365
            rule_id            = 3
            units              = "DAY"
          },
        ]
      }
    }
  }

  assert {
    condition     = output.arns["app1"] != null
    error_message = "A rule 3 retention_duration of exactly 365 (the documented maximum) should be allowed."
  }
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong -- find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
