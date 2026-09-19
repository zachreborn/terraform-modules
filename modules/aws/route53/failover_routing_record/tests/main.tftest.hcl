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

run "record_of_exactly_255_characters_passes_through_unchanged" {
  command = plan

  variables {
    zone_id                      = "Z1234567890ABC"
    name                         = "app.example.com"
    type                         = "TXT"
    records                      = [join("", [for i in range(255) : "a"])]
    set_identifier               = "primary"
    failover_routing_policy_type = "PRIMARY"
  }

  assert {
    condition     = tolist(aws_route53_record.this.records)[0] == join("", [for i in range(255) : "a"])
    error_message = "An exactly-255-character record should pass through unchanged with no trailing \"\" separator (fixes #394)."
  }

  assert {
    condition     = length(tolist(aws_route53_record.this.records)[0]) == 255
    error_message = "An exactly-255-character record must stay 255 characters long, not 257 (no trailing \"\" separator)."
  }
}

run "record_of_exactly_510_characters_gets_one_separator_between_chunks" {
  command = plan

  variables {
    zone_id                      = "Z1234567890ABC"
    name                         = "app.example.com"
    type                         = "TXT"
    records                      = [join("", [for i in range(510) : "a"])]
    set_identifier               = "primary"
    failover_routing_policy_type = "PRIMARY"
  }

  assert {
    condition     = tolist(aws_route53_record.this.records)[0] == "${join("", [for i in range(255) : "a"])}\"\"${join("", [for i in range(255) : "a"])}"
    error_message = "An exactly-510-character record should split into <255>\"\"<255> with exactly one separator between the two chunks and none after the last (fixes #394)."
  }

  assert {
    condition     = length(tolist(aws_route53_record.this.records)[0]) == 512
    error_message = "An exactly-510-character record must be 512 characters long (510 content + one 2-character separator), not 514."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
