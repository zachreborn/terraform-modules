# Native OpenTofu tests for issue #476: captcha/challenge rule[*].action support and
# rule[*].custom_request_handling (insert_header) coverage on the allow/count/captcha/challenge
# actions. All cases run fully offline via mock_provider/mock_resource -- no real credentials or
# backend are required:
#   tofu init -backend=false && tofu test
#
# See AGENTS.md > Module Design Specifications > Native Test Coverage for the full requirement.
# Baseline ACL/rule coverage lives in main.tftest.hcl; captcha_config/challenge_config regression
# coverage lives in captcha_challenge_config.tftest.hcl. Neither of those files is modified here.

mock_provider "aws" {
  mock_resource "aws_wafv2_web_acl" {
    defaults = {
      id  = "webacl-mock"
      arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/example-acl/0123456789abcdef"
    }
  }
}

###########################
# Valid baseline
###########################

run "plan_succeeds_with_captcha_action" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      captcha_bad_ips = {
        name     = "captcha-bad-ips"
        priority = 1
        action   = "captcha"
        statement = {
          ip_set_reference_statement = {
            arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "captcha-bad-ips"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["captcha-bad-ips"].action).captcha) == 1
    error_message = "A rule with action = 'captcha' should emit exactly one captcha action block."
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["captcha-bad-ips"].action).allow) == 0
    error_message = "A rule with action = 'captcha' should not emit an allow action block."
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["captcha-bad-ips"].action).block) == 0
    error_message = "A rule with action = 'captcha' should not emit a block action block."
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["captcha-bad-ips"].action).count) == 0
    error_message = "A rule with action = 'captcha' should not emit a count action block."
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["captcha-bad-ips"].action).challenge) == 0
    error_message = "A rule with action = 'captcha' should not emit a challenge action block."
  }

  assert {
    condition     = output.waf_acl_arn == aws_wafv2_web_acl.this.arn
    error_message = "waf_acl_arn output should equal the WebACL resource's arn even when a rule uses the captcha action."
  }

  assert {
    condition     = output.waf_acl_name == aws_wafv2_web_acl.this.name
    error_message = "waf_acl_name output should equal the WebACL resource's name even when a rule uses the captcha action."
  }
}

###########################
# Conditional branch coverage: one case per side of every new/changed
# for_each guard inside dynamic "action"
###########################

run "plan_succeeds_with_challenge_action" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      challenge_bad_ips = {
        name     = "challenge-bad-ips"
        priority = 1
        action   = "challenge"
        statement = {
          ip_set_reference_statement = {
            arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "challenge-bad-ips"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["challenge-bad-ips"].action).challenge) == 1
    error_message = "A rule with action = 'challenge' should emit exactly one challenge action block."
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["challenge-bad-ips"].action).captcha) == 0
    error_message = "A rule with action = 'challenge' should not emit a captcha action block."
  }
}

run "allow_action_still_emits_only_allow" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      allow_good_ips = {
        name     = "allow-good-ips"
        priority = 1
        action   = "allow"
        statement = {
          ip_set_reference_statement = {
            arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "allow-good-ips"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["allow-good-ips"].action).allow) == 1
    error_message = "A rule with action = 'allow' should still emit exactly one allow action block (regression guard)."
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["allow-good-ips"].action).captcha) == 0
    error_message = "A rule with action = 'allow' should not emit a captcha action block."
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["allow-good-ips"].action).challenge) == 0
    error_message = "A rule with action = 'allow' should not emit a challenge action block."
  }
}

run "block_action_still_emits_only_block" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      block_bad_ips = {
        name     = "block-bad-ips"
        priority = 1
        action   = "block"
        statement = {
          ip_set_reference_statement = {
            arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "block-bad-ips"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["block-bad-ips"].action).block) == 1
    error_message = "A rule with action = 'block' should still emit exactly one block action block (regression guard)."
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["block-bad-ips"].action).captcha) == 0
    error_message = "A rule with action = 'block' should not emit a captcha action block."
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["block-bad-ips"].action).challenge) == 0
    error_message = "A rule with action = 'block' should not emit a challenge action block."
  }
}

run "count_action_still_emits_only_count" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      count_bad_ips = {
        name     = "count-bad-ips"
        priority = 1
        action   = "count"
        statement = {
          ip_set_reference_statement = {
            arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "count-bad-ips"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["count-bad-ips"].action).count) == 1
    error_message = "A rule with action = 'count' should still emit exactly one count action block (regression guard)."
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["count-bad-ips"].action).captcha) == 0
    error_message = "A rule with action = 'count' should not emit a captcha action block."
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["count-bad-ips"].action).challenge) == 0
    error_message = "A rule with action = 'count' should not emit a challenge action block."
  }
}

run "override_action_rule_emits_no_action_block" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      aws_managed_common_rules = {
        name            = "aws-managed-common-rules"
        priority        = 1
        override_action = "none"
        statement = {
          managed_rule_group_statement = {
            name        = "AWSManagedRulesCommonRuleSet"
            vendor_name = "AWS"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "aws-managed-common-rules"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  assert {
    condition     = length(aws_wafv2_web_acl_rule.this["aws-managed-common-rules"].action) == 0
    error_message = "A managed-rule-group rule with no action (action == null) must not emit any action block."
  }

  assert {
    condition     = length(aws_wafv2_web_acl_rule.this["aws-managed-common-rules"].override_action) == 1
    error_message = "A managed-rule-group rule must still emit exactly one override_action block."
  }
}

run "captcha_action_without_custom_request_handling" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      captcha_bad_ips = {
        name     = "captcha-bad-ips"
        priority = 1
        action   = "captcha"
        statement = {
          ip_set_reference_statement = {
            arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "captcha-bad-ips"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["captcha-bad-ips"].action).captcha) == 1
    error_message = "The captcha action block should still be present when custom_request_handling is omitted."
  }

  assert {
    condition     = length(one(one(aws_wafv2_web_acl_rule.this["captcha-bad-ips"].action).captcha).custom_request_handling) == 0
    error_message = "custom_request_handling should not be emitted under captcha when omitted from the rule (false side of the nested guard)."
  }
}

run "captcha_action_with_custom_request_handling" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      captcha_bad_ips = {
        name     = "captcha-bad-ips"
        priority = 1
        action   = "captcha"
        custom_request_handling = {
          insert_header = [
            { name = "x-captcha-rule", value = "triggered" }
          ]
        }
        statement = {
          ip_set_reference_statement = {
            arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "captcha-bad-ips"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  assert {
    condition     = length(one(one(aws_wafv2_web_acl_rule.this["captcha-bad-ips"].action).captcha).custom_request_handling) == 1
    error_message = "custom_request_handling should be emitted under captcha when set (true side of the nested guard)."
  }

  assert {
    condition     = length(one(one(one(aws_wafv2_web_acl_rule.this["captcha-bad-ips"].action).captcha).custom_request_handling).insert_header) == 1
    error_message = "insert_header should be emitted exactly once."
  }

  assert {
    condition     = one(one(one(aws_wafv2_web_acl_rule.this["captcha-bad-ips"].action).captcha).custom_request_handling).insert_header[0].name == "x-captcha-rule"
    error_message = "insert_header's name should equal the caller-supplied value."
  }

  assert {
    condition     = one(one(one(aws_wafv2_web_acl_rule.this["captcha-bad-ips"].action).captcha).custom_request_handling).insert_header[0].value == "triggered"
    error_message = "insert_header's value should equal the caller-supplied value."
  }
}

run "challenge_action_with_multiple_insert_headers" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      challenge_bad_ips = {
        name     = "challenge-bad-ips"
        priority = 1
        action   = "challenge"
        custom_request_handling = {
          insert_header = [
            { name = "x-challenge-rule", value = "triggered" },
            { name = "x-challenge-source", value = "waf" },
          ]
        }
        statement = {
          ip_set_reference_statement = {
            arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "challenge-bad-ips"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  assert {
    condition     = length(one(one(one(aws_wafv2_web_acl_rule.this["challenge-bad-ips"].action).challenge).custom_request_handling).insert_header) == 2
    error_message = "Both insert_header entries should be emitted -- the for_each is not single-element-only."
  }

  assert {
    condition     = one(one(one(aws_wafv2_web_acl_rule.this["challenge-bad-ips"].action).challenge).custom_request_handling).insert_header[0].name == "x-challenge-rule"
    error_message = "The first insert_header's name should round-trip."
  }

  assert {
    condition     = one(one(one(aws_wafv2_web_acl_rule.this["challenge-bad-ips"].action).challenge).custom_request_handling).insert_header[1].name == "x-challenge-source"
    error_message = "The second insert_header's name should round-trip."
  }
}

run "allow_action_with_custom_request_handling" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      allow_good_ips = {
        name     = "allow-good-ips"
        priority = 1
        action   = "allow"
        custom_request_handling = {
          insert_header = [
            { name = "x-allow-rule", value = "triggered" }
          ]
        }
        statement = {
          ip_set_reference_statement = {
            arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "allow-good-ips"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  assert {
    condition     = length(one(one(aws_wafv2_web_acl_rule.this["allow-good-ips"].action).allow).custom_request_handling) == 1
    error_message = "custom_request_handling should be emitted under the pre-existing allow branch."
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["allow-good-ips"].action).captcha) == 0
    error_message = "custom_request_handling on an allow rule must not cause a captcha block to be emitted."
  }
}

run "count_action_with_custom_request_handling" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      count_bad_ips = {
        name     = "count-bad-ips"
        priority = 1
        action   = "count"
        custom_request_handling = {
          insert_header = [
            { name = "x-count-rule", value = "triggered" }
          ]
        }
        statement = {
          ip_set_reference_statement = {
            arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "count-bad-ips"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  assert {
    condition     = length(one(one(aws_wafv2_web_acl_rule.this["count-bad-ips"].action).count).custom_request_handling) == 1
    error_message = "custom_request_handling should be emitted under the pre-existing count branch."
  }
}

###########################
# Validation coverage: one expect_failures case per new validation {} rule
###########################

run "rejects_unknown_action_value" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      bad_action = {
        name     = "bad-action"
        priority = 1
        action   = "invalid-action"
        statement = {
          ip_set_reference_statement = {
            arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "bad-action"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  expect_failures = [var.rule]
}

run "rejects_custom_request_handling_with_block_action" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      block_bad_ips = {
        name     = "block-bad-ips"
        priority = 1
        action   = "block"
        custom_request_handling = {
          insert_header = [
            { name = "x-block-rule", value = "triggered" }
          ]
        }
        statement = {
          ip_set_reference_statement = {
            arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "block-bad-ips"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  expect_failures = [var.rule]
}

run "rejects_custom_request_handling_without_action" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      aws_managed_common_rules = {
        name            = "aws-managed-common-rules"
        priority        = 1
        override_action = "none"
        custom_request_handling = {
          insert_header = [
            { name = "x-managed-rule", value = "triggered" }
          ]
        }
        statement = {
          managed_rule_group_statement = {
            name        = "AWSManagedRulesCommonRuleSet"
            vendor_name = "AWS"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "aws-managed-common-rules"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  expect_failures = [var.rule]
}

run "rejects_empty_insert_header_list" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      captcha_bad_ips = {
        name     = "captcha-bad-ips"
        priority = 1
        action   = "captcha"
        custom_request_handling = {
          insert_header = []
        }
        statement = {
          ip_set_reference_statement = {
            arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "captcha-bad-ips"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  expect_failures = [var.rule]
}

###########################
# Interaction with captcha_config / challenge_config
###########################

run "captcha_action_with_explicit_captcha_config" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      captcha_bad_ips = {
        name     = "captcha-bad-ips"
        priority = 1
        action   = "captcha"
        captcha_config = {
          immunity_time_property = {
            immunity_time = 120
          }
        }
        statement = {
          ip_set_reference_statement = {
            arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "captcha-bad-ips"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["captcha-bad-ips"].action).captcha) == 1
    error_message = "The captcha action block should be present alongside an explicit captcha_config."
  }

  assert {
    condition     = one(aws_wafv2_web_acl_rule.this["captcha-bad-ips"].captcha_config).immunity_time_property[0].immunity_time == 120
    error_message = "captcha_config's immunity_time should reflect the caller-supplied value even when action = 'captcha' triggers the rule."
  }
}

run "challenge_action_with_explicit_challenge_config" {
  command = plan

  variables {
    name = "example-acl"

    rule = {
      challenge_bad_ips = {
        name     = "challenge-bad-ips"
        priority = 1
        action   = "challenge"
        challenge_config = {
          immunity_time_property = {
            immunity_time = 90
          }
        }
        statement = {
          ip_set_reference_statement = {
            arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "challenge-bad-ips"
          sampled_requests_enabled   = true
        }
      }
    }
  }

  assert {
    condition     = length(one(aws_wafv2_web_acl_rule.this["challenge-bad-ips"].action).challenge) == 1
    error_message = "The challenge action block should be present alongside an explicit challenge_config."
  }

  assert {
    condition     = one(aws_wafv2_web_acl_rule.this["challenge-bad-ips"].challenge_config).immunity_time_property[0].immunity_time == 90
    error_message = "challenge_config's immunity_time should reflect the caller-supplied value even when action = 'challenge' triggers the rule."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block
# fails, treat it as a signal that the module code has a bug and fix the root cause
# in main.tf / variables.tf, then re-run `tofu test` until it passes for the right reason.
