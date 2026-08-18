# Regression coverage for the captcha_config/challenge_config fix:
# aws_wafv2_web_acl_rule.this used to emit static captcha_config and
# challenge_config blocks (defaulted to immunity_time=300) on every single rule,
# regardless of the rule's action/statement. AWS's WAFv2 API rejects
# CaptchaConfig/ChallengeConfig on rules that use managed_rule_group_statement +
# override_action, so any rule referencing a managed rule group would fail to
# apply. The fix makes both blocks `dynamic`, gated on `!= null`, and removes the
# non-null variable default so they are only emitted when a caller opts in.
# All cases run fully offline via mock_provider/mock_resource:
#   tofu init -backend=false && tofu test

mock_provider "aws" {
  mock_resource "aws_wafv2_web_acl" {
    defaults = {
      id  = "webacl-mock"
      arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/example-acl/0123456789abcdef"
    }
  }
}

# Omitting captcha_config/challenge_config from a rule must not emit either
# block at all -- this is the core of the fix (previously both were always
# emitted with a static immunity_time=300 default).
run "captcha_and_challenge_config_omitted_by_default" {
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
    condition     = length(aws_wafv2_web_acl_rule.this["block-bad-ips"].captcha_config) == 0
    error_message = "captcha_config should not be emitted when omitted from the rule (regression check for the always-emitted bug)."
  }

  assert {
    condition     = length(aws_wafv2_web_acl_rule.this["block-bad-ips"].challenge_config) == 0
    error_message = "challenge_config should not be emitted when omitted from the rule (regression check for the always-emitted bug)."
  }
}

# Explicitly setting captcha_config/challenge_config must still emit the block,
# with the caller's immunity_time honored.
run "explicit_captcha_and_challenge_config_emit_blocks" {
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
        captcha_config = {
          immunity_time_property = {
            immunity_time = 120
          }
        }
        challenge_config = {
          immunity_time_property = {
            immunity_time = 90
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
    condition     = length(aws_wafv2_web_acl_rule.this["block-bad-ips"].captcha_config) == 1
    error_message = "captcha_config should be emitted exactly once when explicitly set."
  }

  assert {
    condition     = one(aws_wafv2_web_acl_rule.this["block-bad-ips"].captcha_config).immunity_time_property[0].immunity_time == 120
    error_message = "captcha_config's immunity_time should reflect the caller-supplied value."
  }

  assert {
    condition     = length(aws_wafv2_web_acl_rule.this["block-bad-ips"].challenge_config) == 1
    error_message = "challenge_config should be emitted exactly once when explicitly set."
  }

  assert {
    condition     = one(aws_wafv2_web_acl_rule.this["block-bad-ips"].challenge_config).immunity_time_property[0].immunity_time == 90
    error_message = "challenge_config's immunity_time should reflect the caller-supplied value."
  }
}

# The direct regression test for the reported bug: a rule that uses
# managed_rule_group_statement + override_action (the exact combination AWS
# rejects when CaptchaConfig/ChallengeConfig is present) must plan successfully
# with no captcha_config/challenge_config blocks by default.
run "managed_rule_group_rule_plans_without_captcha_or_challenge_blocks" {
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
    condition     = length(aws_wafv2_web_acl_rule.this["aws-managed-common-rules"].captcha_config) == 0
    error_message = "A managed-rule-group rule must not have a captcha_config block (AWS rejects CaptchaConfig on managed rule groups)."
  }

  assert {
    condition     = length(aws_wafv2_web_acl_rule.this["aws-managed-common-rules"].challenge_config) == 0
    error_message = "A managed-rule-group rule must not have a challenge_config block (AWS rejects ChallengeConfig on managed rule groups)."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block
# fails, treat it as a signal that the module code has a bug and fix the root cause
# in main.tf / variables.tf / outputs.tf, then re-run `tofu test` until it passes for
# the right reason.
