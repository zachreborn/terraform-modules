# Native OpenTofu tests for the waf module. All cases run fully offline via
# mock_provider/mock_resource -- no real credentials or backend are required:
#   tofu init -backend=false && tofu test
#
# See AGENTS.md > Module Design Specifications > Native Test Coverage for the full
# requirement. captcha_config/challenge_config regression coverage lives in
# captcha_challenge_config.tftest.hcl alongside this baseline file.

mock_provider "aws" {
  mock_resource "aws_wafv2_web_acl" {
    defaults = {
      id  = "webacl-mock"
      arn = "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/example-acl/0123456789abcdef"
    }
  }

  mock_resource "aws_wafv2_ip_set" {
    defaults = {
      id  = "ipset-mock"
      arn = "arn:aws:wafv2:us-east-1:123456789012:regional/ipset/example-ipset/0123456789abcdef"
    }
  }
}

# Valid baseline: a WebACL with an IP set and a single IP-set-reference rule.
run "plan_succeeds_with_baseline_acl" {
  command = plan

  variables {
    name = "example-acl"

    ip_sets = {
      blocked = {
        name      = "blocked-ips"
        addresses = ["203.0.113.0/24"]
      }
    }

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
    condition     = aws_wafv2_web_acl.this.name == "example-acl"
    error_message = "The WebACL's name should equal the name input."
  }

  assert {
    condition     = length(aws_wafv2_ip_set.this) == 1
    error_message = "Expected exactly one IP set to be created."
  }

  assert {
    condition     = length(aws_wafv2_web_acl_rule.this) == 1
    error_message = "Expected exactly one rule to be created."
  }

  assert {
    condition     = output.waf_acl_arn == aws_wafv2_web_acl.this.arn
    error_message = "waf_acl_arn output should equal the WebACL resource's arn."
  }

  assert {
    condition     = output.waf_acl_name == aws_wafv2_web_acl.this.name
    error_message = "waf_acl_name output should equal the WebACL resource's name."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block
# fails, treat it as a signal that the module code has a bug and fix the root cause
# in main.tf / variables.tf / outputs.tf, then re-run `tofu test` until it passes for
# the right reason.
