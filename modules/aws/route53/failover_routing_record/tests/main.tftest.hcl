mock_provider "aws" {}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    zone_id                      = "Z1234567890ABC"
    name                         = "app.example.com"
    type                         = "CNAME"
    records                      = ["primary-target.example.com"]
    set_identifier               = "primary"
    health_check_id              = "hc-1234567890"
    failover_routing_policy_type = "PRIMARY"
  }

  assert {
    condition     = aws_route53_record.this.zone_id == "Z1234567890ABC"
    error_message = "zone_id should pass through unchanged."
  }

  assert {
    condition     = aws_route53_record.this.name == "app.example.com"
    error_message = "name should pass through unchanged."
  }

  assert {
    condition     = contains(aws_route53_record.this.records, "primary-target.example.com")
    error_message = "records should pass through unchanged when under the 255 character split threshold."
  }

  assert {
    condition     = aws_route53_record.this.set_identifier == "primary"
    error_message = "set_identifier should pass through unchanged."
  }

  assert {
    condition     = aws_route53_record.this.health_check_id == "hc-1234567890"
    error_message = "health_check_id should pass through unchanged."
  }

  assert {
    condition     = aws_route53_record.this.failover_routing_policy[0].type == "PRIMARY"
    error_message = "failover_routing_policy.type should be PRIMARY."
  }
}

run "failover_secondary_type_is_honored" {
  command = plan

  variables {
    zone_id                      = "Z1234567890ABC"
    name                         = "app.example.com"
    type                         = "CNAME"
    records                      = ["secondary-target.example.com"]
    set_identifier               = "secondary"
    failover_routing_policy_type = "SECONDARY"
  }

  assert {
    condition     = aws_route53_record.this.failover_routing_policy[0].type == "SECONDARY"
    error_message = "failover_routing_policy.type should be SECONDARY when explicitly set."
  }
}

run "ttl_defaults_to_300" {
  command = plan

  variables {
    zone_id                      = "Z1234567890ABC"
    name                         = "app.example.com"
    type                         = "CNAME"
    records                      = ["primary-target.example.com"]
    set_identifier               = "primary"
    failover_routing_policy_type = "PRIMARY"
  }

  assert {
    condition     = aws_route53_record.this.ttl == 300
    error_message = "ttl should default to 300 when unset."
  }
}

run "ttl_override_is_honored" {
  command = plan

  variables {
    zone_id                      = "Z1234567890ABC"
    name                         = "app.example.com"
    type                         = "CNAME"
    ttl                          = 60
    records                      = ["primary-target.example.com"]
    set_identifier               = "primary"
    failover_routing_policy_type = "PRIMARY"
  }

  assert {
    condition     = aws_route53_record.this.ttl == 60
    error_message = "Explicit ttl override should be honored."
  }
}

run "record_longer_than_255_characters_is_split" {
  command = plan

  variables {
    zone_id                      = "Z1234567890ABC"
    name                         = "app.example.com"
    type                         = "TXT"
    records                      = [join("", [for i in range(300) : "a"])]
    set_identifier               = "primary"
    failover_routing_policy_type = "PRIMARY"
  }

  assert {
    condition     = contains(aws_route53_record.this.records, "${join("", [for i in range(255) : "a"])}\"\"${join("", [for i in range(45) : "a"])}")
    error_message = "A 300 character record should have an empty-string separator inserted after the 255th character."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
