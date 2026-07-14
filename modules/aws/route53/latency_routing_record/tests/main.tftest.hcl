mock_provider "aws" {}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    zone_id                       = "Z1234567890ABC"
    name                          = "app.example.com"
    type                          = "CNAME"
    records                       = ["use1-target.example.com"]
    set_identifier                = "use1"
    latency_routing_policy_region = "us-east-1"
  }

  assert {
    condition     = aws_route53_record.this.zone_id == "Z1234567890ABC"
    error_message = "zone_id should pass through unchanged."
  }

  assert {
    condition     = contains(aws_route53_record.this.records, "use1-target.example.com")
    error_message = "records should pass through unchanged when under the 255 character split threshold."
  }

  assert {
    condition     = aws_route53_record.this.latency_routing_policy[0].region == "us-east-1"
    error_message = "latency_routing_policy.region should be honored."
  }
}

run "different_region_is_honored" {
  command = plan

  variables {
    zone_id                       = "Z1234567890ABC"
    name                          = "app.example.com"
    type                          = "CNAME"
    records                       = ["euw1-target.example.com"]
    set_identifier                = "euw1"
    latency_routing_policy_region = "eu-west-1"
  }

  assert {
    condition     = aws_route53_record.this.latency_routing_policy[0].region == "eu-west-1"
    error_message = "latency_routing_policy.region should reflect the configured region."
  }
}

run "ttl_defaults_to_300" {
  command = plan

  variables {
    zone_id                       = "Z1234567890ABC"
    name                          = "app.example.com"
    type                          = "CNAME"
    records                       = ["use1-target.example.com"]
    set_identifier                = "use1"
    latency_routing_policy_region = "us-east-1"
  }

  assert {
    condition     = aws_route53_record.this.ttl == 300
    error_message = "ttl should default to 300 when unset."
  }
}

run "ttl_override_is_honored" {
  command = plan

  variables {
    zone_id                       = "Z1234567890ABC"
    name                          = "app.example.com"
    type                          = "CNAME"
    ttl                           = 60
    records                       = ["use1-target.example.com"]
    set_identifier                = "use1"
    latency_routing_policy_region = "us-east-1"
  }

  assert {
    condition     = aws_route53_record.this.ttl == 60
    error_message = "Explicit ttl override should be honored."
  }
}

run "record_longer_than_255_characters_is_split" {
  command = plan

  variables {
    zone_id                       = "Z1234567890ABC"
    name                          = "app.example.com"
    type                          = "TXT"
    records                       = [join("", [for i in range(300) : "a"])]
    set_identifier                = "use1"
    latency_routing_policy_region = "us-east-1"
  }

  assert {
    condition     = contains(aws_route53_record.this.records, "${join("", [for i in range(255) : "a"])}\"\"${join("", [for i in range(45) : "a"])}")
    error_message = "A 300 character record should have an empty-string separator inserted after the 255th character."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
