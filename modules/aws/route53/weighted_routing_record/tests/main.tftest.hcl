mock_provider "aws" {}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    zone_id                        = "Z1234567890ABC"
    name                           = "app.example.com"
    type                           = "CNAME"
    records                        = ["blue-target.example.com"]
    set_identifier                 = "blue"
    weighted_routing_policy_weight = 80
  }

  assert {
    condition     = aws_route53_record.this.zone_id == "Z1234567890ABC"
    error_message = "zone_id should pass through unchanged."
  }

  assert {
    condition     = contains(aws_route53_record.this.records, "blue-target.example.com")
    error_message = "records should pass through unchanged when under the 255 character split threshold."
  }

  assert {
    condition     = aws_route53_record.this.weighted_routing_policy[0].weight == 80
    error_message = "weighted_routing_policy.weight should be honored."
  }
}

run "zero_weight_is_honored" {
  command = plan

  variables {
    zone_id                        = "Z1234567890ABC"
    name                           = "app.example.com"
    type                           = "CNAME"
    records                        = ["green-target.example.com"]
    set_identifier                 = "green"
    weighted_routing_policy_weight = 0
  }

  assert {
    condition     = aws_route53_record.this.weighted_routing_policy[0].weight == 0
    error_message = "A weight of 0 (effectively disabling this record) should be honored, not treated as unset."
  }
}

run "ttl_defaults_to_300" {
  command = plan

  variables {
    zone_id                        = "Z1234567890ABC"
    name                           = "app.example.com"
    type                           = "CNAME"
    records                        = ["blue-target.example.com"]
    set_identifier                 = "blue"
    weighted_routing_policy_weight = 80
  }

  assert {
    condition     = aws_route53_record.this.ttl == 300
    error_message = "ttl should default to 300 when unset."
  }
}

run "ttl_override_is_honored" {
  command = plan

  variables {
    zone_id                        = "Z1234567890ABC"
    name                           = "app.example.com"
    type                           = "CNAME"
    ttl                            = 60
    records                        = ["blue-target.example.com"]
    set_identifier                 = "blue"
    weighted_routing_policy_weight = 80
  }

  assert {
    condition     = aws_route53_record.this.ttl == 60
    error_message = "Explicit ttl override should be honored."
  }
}

run "record_longer_than_255_characters_is_split" {
  command = plan

  variables {
    zone_id                        = "Z1234567890ABC"
    name                           = "app.example.com"
    type                           = "TXT"
    records                        = [join("", [for i in range(300) : "a"])]
    set_identifier                 = "blue"
    weighted_routing_policy_weight = 80
  }

  assert {
    condition     = contains(aws_route53_record.this.records, "${join("", [for i in range(255) : "a"])}\"\"${join("", [for i in range(45) : "a"])}")
    error_message = "A 300 character record should have an empty-string separator inserted after the 255th character."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
