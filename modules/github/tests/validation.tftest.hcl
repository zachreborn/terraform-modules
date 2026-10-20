mock_provider "github" {}

variables {
  profiles = {
    default = {}
  }

  organization_policy = {
    ruleset_name               = "change_control"
    minimum_required_approvals = 1
    verified_at                = "2026-09-14T10:00:00Z"
  }
}

run "accepts_valid_baseline" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "default"
        management_stage = "managed"
      }
    }
  }

  assert {
    condition     = length(github_repository.this) == 1
    error_message = "The valid baseline must plan one managed repository."
  }
}

run "rejects_invalid_profile_fork_value" {
  command = plan

  variables {
    profiles = {
      default = { fork = "yes" }
    }
    repositories = {}
  }

  expect_failures = [var.profiles]
}

run "rejects_missing_required_profile_keys" {
  command = plan

  variables {
    required_profile_keys = ["default", "production"]
    profiles = {
      default = {}
    }
    repositories = {}
  }

  expect_failures = [var.profiles]
}

run "accepts_required_profile_keys_when_present" {
  command = plan

  variables {
    required_profile_keys = ["default", "production"]
    profiles = {
      default    = {}
      production = {}
    }
    repositories = {
      example = {
        profile          = "production"
        management_stage = "managed"
      }
    }
  }

  assert {
    condition     = length(github_repository.this) == 1
    error_message = "Caller-defined required profile keys must plan when all keys exist."
  }
}

run "rejects_empty_required_profile_key" {
  command = plan

  variables {
    required_profile_keys = [" "]
    profiles = {
      default = {}
    }
    repositories = {}
  }

  expect_failures = [var.required_profile_keys]
}

run "rejects_invalid_profile_visibility" {
  command = plan

  variables {
    profiles = {
      default = { visibility = "secret" }
    }
    repositories = {}
  }

  expect_failures = [var.profiles]
}

run "rejects_empty_profile_topic" {
  command = plan

  variables {
    profiles = {
      default = { topics = [" "] }
    }
    repositories = {}
  }

  expect_failures = [var.profiles]
}

run "rejects_invalid_profile_security_status" {
  command = plan

  variables {
    profiles = {
      default = {
        security_and_analysis = {
          secret_scanning = "unknown"
        }
      }
    }
    repositories = {}
  }

  expect_failures = [var.profiles]
}

run "rejects_invalid_override_fork_value" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "default"
        management_stage = "managed"
        overrides = {
          fork = "yes"
        }
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_unknown_repository_profile" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "unknown"
        management_stage = "managed"
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_unknown_management_stage" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "default"
        management_stage = "adopted"
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_invalid_repository_name" {
  command = plan

  variables {
    repositories = {
      "" = {
        profile          = "default"
        management_stage = "managed"
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_overlong_repository_name" {
  command = plan

  variables {
    repositories = {
      "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" = {
        profile          = "default"
        management_stage = "managed"
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_invalid_override_visibility" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "default"
        management_stage = "managed"
        overrides = {
          visibility = "secret"
        }
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_empty_override_topic" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "default"
        management_stage = "managed"
        overrides = {
          topics = [""]
        }
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_invalid_override_security_status" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "default"
        management_stage = "managed"
        overrides = {
          security_and_analysis = {
            secret_scanning = "unknown"
          }
        }
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_empty_status_check" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "default"
        management_stage = "managed"
        supplemental_rules = {
          extra_status_checks = [" "]
        }
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_weaker_supplemental_approval_count" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "default"
        management_stage = "managed"
        supplemental_rules = {
          required_approvals = 0
        }
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_excessive_supplemental_approval_count" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "default"
        management_stage = "managed"
        supplemental_rules = {
          required_approvals = 11
        }
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_fractional_supplemental_approval_count" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "default"
        management_stage = "managed"
        supplemental_rules = {
          required_approvals = 1.5
        }
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_supplemental_bypass_actors" {
  command = plan

  variables {
    repositories = {
      example = {
        profile          = "default"
        management_stage = "managed"
        supplemental_rules = {
          bypass_actors = [{
            actor_id   = 1
            actor_type = "Team"
          }]
        }
      }
    }
  }

  expect_failures = [var.repositories]
}

run "rejects_wrong_organization_ruleset" {
  command = plan

  variables {
    repositories = {}
    organization_policy = {
      ruleset_name               = "different"
      minimum_required_approvals = 1
      verified_at                = "2026-09-14T10:00:00Z"
    }
  }

  expect_failures = [var.organization_policy]
}

run "rejects_invalid_organization_approval_count" {
  command = plan

  variables {
    repositories = {}
    organization_policy = {
      ruleset_name               = "change_control"
      minimum_required_approvals = 1.5
      verified_at                = "2026-09-14T10:00:00Z"
    }
  }

  expect_failures = [var.organization_policy]
}

run "rejects_negative_organization_approval_count" {
  command = plan

  variables {
    repositories = {}
    organization_policy = {
      ruleset_name               = "change_control"
      minimum_required_approvals = -1
      verified_at                = "2026-09-14T10:00:00Z"
    }
  }

  expect_failures = [var.organization_policy]
}

run "rejects_excessive_organization_approval_count" {
  command = plan

  variables {
    repositories = {}
    organization_policy = {
      ruleset_name               = "change_control"
      minimum_required_approvals = 11
      verified_at                = "2026-09-14T10:00:00Z"
    }
  }

  expect_failures = [var.organization_policy]
}

run "rejects_invalid_policy_snapshot_timestamp" {
  command = plan

  variables {
    repositories = {}
    organization_policy = {
      ruleset_name               = "change_control"
      minimum_required_approvals = 1
      verified_at                = "not-a-timestamp"
    }
  }

  expect_failures = [var.organization_policy]
}
