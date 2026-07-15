mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_resource "aws_amplify_app" {
    defaults = {
      id             = "d1234567890abc"
      arn            = "arn:aws:amplify:us-east-1:123456789012:apps/d1234567890abc"
      default_domain = "d1234567890abc.amplifyapp.com"
    }
  }
}

run "valid_baseline_plans_successfully" {
  command = plan

  variables {
    name     = "my-app"
    branches = {}
  }

  assert {
    condition     = aws_amplify_app.this.name == "my-app"
    error_message = "name should pass through unchanged."
  }

  assert {
    condition     = aws_amplify_app.this.platform == "WEB"
    error_message = "platform should default to WEB."
  }

  assert {
    condition     = length(aws_amplify_app.this.auto_branch_creation_config) == 0
    error_message = "auto_branch_creation_config block should be absent when var.auto_branch_creation_config is null."
  }

  assert {
    condition     = length(aws_amplify_app.this.cache_config) == 1
    error_message = "cache_config block should be present by default (cache_config_type defaults to AMPLIFY_MANAGED, non-null)."
  }

  assert {
    condition     = aws_amplify_app.this.cache_config[0].type == "AMPLIFY_MANAGED"
    error_message = "cache_config.type should default to AMPLIFY_MANAGED."
  }

  assert {
    condition     = length(aws_amplify_app.this.custom_rule) == 0
    error_message = "custom_rule blocks should be absent when var.custom_rules is null."
  }

  assert {
    condition     = length(aws_amplify_branch.this) == 0
    error_message = "No branches should be planned when var.branches is empty."
  }

  assert {
    condition     = length(aws_amplify_domain_association.this) == 0
    error_message = "No domain associations should be planned when var.branches is empty."
  }

  assert {
    condition     = output.app_id == "d1234567890abc"
    error_message = "app_id output should expose the app's id."
  }

  assert {
    condition     = output.app_arn == "arn:aws:amplify:us-east-1:123456789012:apps/d1234567890abc"
    error_message = "app_arn output should expose the app's arn."
  }

  assert {
    condition     = output.default_domain == "d1234567890abc.amplifyapp.com"
    error_message = "default_domain output should expose the app's default_domain."
  }

  assert {
    condition     = output.sns_topic_arn == null
    error_message = "sns_topic_arn output should be null when enable_notifications is false."
  }

  assert {
    condition     = output.notification_event_rule_arn == null
    error_message = "notification_event_rule_arn output should be null when enable_notifications is false."
  }
}

# Core regression for issue #406: passing branches = null previously crashed the
# plan with "Invalid for_each argument" on aws_amplify_domain_association.this.
# nullable = false + default = {} now coerces null to {}, so both the branch and
# domain-association resources plan with zero instances (matching the existing
# null-safe behavior of aws_amplify_branch.this).
run "branches_null_plans_with_zero_resources" {
  command = plan

  variables {
    name     = "my-app"
    branches = null
  }

  assert {
    condition     = length(aws_amplify_branch.this) == 0
    error_message = "branches = null should coerce to {} and plan zero branches."
  }

  assert {
    condition     = length(aws_amplify_domain_association.this) == 0
    error_message = "branches = null should coerce to {} and plan zero domain associations (no Invalid for_each crash)."
  }
}

# Exercises the new default = {} by leaving branches unset entirely, confirming
# the variable is now optional and defaults to an empty map.
run "branches_default_empty_plans" {
  command = plan

  variables {
    name = "my-app"
  }

  assert {
    condition     = length(aws_amplify_branch.this) == 0
    error_message = "Omitting branches should default to {} and plan zero branches."
  }

  assert {
    condition     = length(aws_amplify_domain_association.this) == 0
    error_message = "Omitting branches should default to {} and plan zero domain associations."
  }
}

run "auto_branch_creation_config_toggle_adds_the_block" {
  command = plan

  variables {
    name     = "my-app"
    branches = {}
    auto_branch_creation_config = {
      build_spec        = "version: 1"
      enable_auto_build = true
      framework         = "Astro"
    }
  }

  assert {
    condition     = length(aws_amplify_app.this.auto_branch_creation_config) == 1
    error_message = "auto_branch_creation_config block should be present when var.auto_branch_creation_config is non-null."
  }

  assert {
    condition     = aws_amplify_app.this.auto_branch_creation_config[0].build_spec == "version: 1"
    error_message = "auto_branch_creation_config.build_spec should pass through unchanged."
  }

  assert {
    condition     = aws_amplify_app.this.auto_branch_creation_config[0].framework == "Astro"
    error_message = "auto_branch_creation_config.framework should pass through unchanged."
  }
}

# Proves that passing null for cache_config_type succeeds (fix for
# https://github.com/zachreborn/terraform-modules/issues/379) and produces no
# cache_config block on aws_amplify_app. This case was previously unreachable
# because the validation block rejected null before main.tf could evaluate the
# dynamic block.
run "cache_config_type_null_omits_cache_config_block" {
  command = plan

  variables {
    name              = "my-app"
    branches          = {}
    cache_config_type = null
  }

  assert {
    condition     = length(aws_amplify_app.this.cache_config) == 0
    error_message = "cache_config block should be absent when cache_config_type = null."
  }
}

run "cache_config_type_no_cookies_succeeds" {
  command = plan

  variables {
    name              = "my-app"
    branches          = {}
    cache_config_type = "AMPLIFY_MANAGED_NO_COOKIES"
  }

  assert {
    condition     = length(aws_amplify_app.this.cache_config) == 1
    error_message = "cache_config block should be present when cache_config_type = AMPLIFY_MANAGED_NO_COOKIES."
  }

  assert {
    condition     = aws_amplify_app.this.cache_config[0].type == "AMPLIFY_MANAGED_NO_COOKIES"
    error_message = "cache_config.type should equal AMPLIFY_MANAGED_NO_COOKIES."
  }
}

run "custom_rules_toggle_adds_dynamic_blocks" {
  command = plan

  variables {
    name     = "my-app"
    branches = {}
    custom_rules = [
      {
        source = "/<*>"
        status = "404-200"
        target = "/404"
      }
    ]
  }

  assert {
    condition     = length(aws_amplify_app.this.custom_rule) == 1
    error_message = "custom_rule block should be present when var.custom_rules has entries."
  }

  assert {
    condition     = aws_amplify_app.this.custom_rule[0].source == "/<*>"
    error_message = "custom_rule.source should pass through unchanged."
  }

  assert {
    condition     = aws_amplify_app.this.custom_rule[0].target == "/404"
    error_message = "custom_rule.target should pass through unchanged."
  }
}

run "single_branch_creates_branch_and_domain_association" {
  command = plan

  variables {
    name = "my-app"
    branches = {
      main = {
        domain_name = "example.org"
        framework   = "Astro"
        stage       = "PRODUCTION"
      }
    }
  }

  assert {
    condition     = length(aws_amplify_branch.this) == 1
    error_message = "Expected exactly one branch to be planned."
  }

  assert {
    condition     = aws_amplify_branch.this["main"].branch_name == "main"
    error_message = "branch_name should equal the map key."
  }

  assert {
    condition     = aws_amplify_branch.this["main"].display_name == "main"
    error_message = "display_name should default to the branch's map key when unset."
  }

  assert {
    condition     = aws_amplify_branch.this["main"].enable_auto_build == true
    error_message = "enable_auto_build should default to true."
  }

  assert {
    condition     = aws_amplify_branch.this["main"].stage == "PRODUCTION"
    error_message = "stage override should be honored."
  }

  assert {
    condition     = length(aws_amplify_domain_association.this) == 1
    error_message = "Expected exactly one domain association to be planned."
  }

  assert {
    condition     = aws_amplify_domain_association.this["main"].domain_name == "example.org"
    error_message = "domain_name should pass through unchanged."
  }

  assert {
    condition     = aws_amplify_domain_association.this["main"].enable_auto_sub_domain == false
    error_message = "enable_auto_sub_domain should default to false."
  }

  assert {
    condition     = length(aws_amplify_domain_association.this["main"].certificate_settings) == 1
    error_message = "certificate_settings block should be present by default (enable_certificate defaults to true)."
  }

  assert {
    condition     = aws_amplify_domain_association.this["main"].certificate_settings[0].type == "AMPLIFY_MANAGED"
    error_message = "certificate_settings.type should default to AMPLIFY_MANAGED."
  }
}

run "disabling_certificate_removes_certificate_settings_block" {
  command = plan

  variables {
    name = "my-app"
    branches = {
      main = {
        domain_name        = "example.org"
        enable_certificate = false
      }
    }
  }

  assert {
    condition     = length(aws_amplify_domain_association.this["main"].certificate_settings) == 0
    error_message = "certificate_settings block should be absent when enable_certificate is false."
  }
}

run "sub_domains_toggle_adds_extra_sub_domain_entry" {
  command = plan

  variables {
    name = "my-app"
    branches = {
      main = {
        domain_name = "example.org"
        sub_domains = ["www"]
      }
    }
  }

  assert {
    condition     = length(aws_amplify_domain_association.this["main"].sub_domain) == 2
    error_message = "Expected the base sub_domain entry (prefix '') plus one entry per item in sub_domains."
  }

  assert {
    condition     = contains([for sd in aws_amplify_domain_association.this["main"].sub_domain : sd.prefix], "www")
    error_message = "Expected a sub_domain entry with prefix 'www'."
  }

  assert {
    condition     = contains([for sd in aws_amplify_domain_association.this["main"].sub_domain : sd.prefix], "")
    error_message = "Expected the base sub_domain entry with an empty prefix."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that the module code has a bug and fix the root cause in main.tf / variables.tf /
# outputs.tf, then re-run `tofu test` until it passes for the right reason.
