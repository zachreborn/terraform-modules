mock_provider "aws" {}

run "plan_succeeds_with_country_based_geolocation" {
  command = plan

  variables {
    zone_id                              = "Z1234567890ABC"
    name                                 = "app.example.com"
    type                                 = "CNAME"
    records                              = ["us-target.example.com"]
    set_identifier                       = "us"
    geolocation_routing_policy_country   = "US"
    geolocation_routing_policy_continent = null
  }

  assert {
    condition     = aws_route53_record.this.zone_id == "Z1234567890ABC"
    error_message = "zone_id should pass through unchanged."
  }

  assert {
    condition     = contains(aws_route53_record.this.records, "us-target.example.com")
    error_message = "records should pass through unchanged when under the 255 character split threshold."
  }

  assert {
    condition     = aws_route53_record.this.geolocation_routing_policy[0].country == "US"
    error_message = "geolocation_routing_policy.country should be honored."
  }
}

run "plan_succeeds_with_continent_based_geolocation" {
  command = plan

  variables {
    zone_id                              = "Z1234567890ABC"
    name                                 = "app.example.com"
    type                                 = "CNAME"
    records                              = ["na-target.example.com"]
    set_identifier                       = "na"
    geolocation_routing_policy_continent = "NA"
  }

  assert {
    condition     = aws_route53_record.this.geolocation_routing_policy[0].continent == "NA"
    error_message = "geolocation_routing_policy.continent should be honored."
  }
}

run "plan_succeeds_with_country_and_subdivision" {
  command = plan

  variables {
    zone_id                                = "Z1234567890ABC"
    name                                   = "app.example.com"
    type                                   = "CNAME"
    records                                = ["wa-target.example.com"]
    set_identifier                         = "us-wa"
    geolocation_routing_policy_country     = "US"
    geolocation_routing_policy_subdivision = "WA"
  }

  assert {
    condition     = aws_route53_record.this.geolocation_routing_policy[0].country == "US"
    error_message = "geolocation_routing_policy.country should be honored alongside subdivision."
  }

  assert {
    condition     = aws_route53_record.this.geolocation_routing_policy[0].subdivision == "WA"
    error_message = "geolocation_routing_policy.subdivision should be honored."
  }
}

run "ttl_defaults_to_300" {
  command = plan

  variables {
    zone_id                            = "Z1234567890ABC"
    name                               = "app.example.com"
    type                               = "CNAME"
    records                            = ["default-target.example.com"]
    set_identifier                     = "default"
    geolocation_routing_policy_country = "*"
  }

  assert {
    condition     = aws_route53_record.this.ttl == 300
    error_message = "ttl should default to 300 when unset."
  }
}

run "ttl_override_is_honored" {
  command = plan

  variables {
    zone_id                            = "Z1234567890ABC"
    name                               = "app.example.com"
    type                               = "CNAME"
    ttl                                = 60
    records                            = ["default-target.example.com"]
    set_identifier                     = "default"
    geolocation_routing_policy_country = "*"
  }

  assert {
    condition     = aws_route53_record.this.ttl == 60
    error_message = "Explicit ttl override should be honored."
  }
}

run "record_longer_than_255_characters_is_split" {
  command = plan

  variables {
    zone_id                            = "Z1234567890ABC"
    name                               = "app.example.com"
    type                               = "TXT"
    records                            = [join("", [for i in range(300) : "a"])]
    set_identifier                     = "default"
    geolocation_routing_policy_country = "*"
  }

  assert {
    condition     = contains(aws_route53_record.this.records, "${join("", [for i in range(255) : "a"])}\"\"${join("", [for i in range(45) : "a"])}")
    error_message = "A 300 character record should have an empty-string separator inserted after the 255th character."
  }
}

run "record_of_exactly_255_characters_passes_through_unchanged" {
  command = plan

  variables {
    zone_id                            = "Z1234567890ABC"
    name                               = "app.example.com"
    type                               = "TXT"
    records                            = [join("", [for i in range(255) : "a"])]
    set_identifier                     = "default"
    geolocation_routing_policy_country = "*"
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
    zone_id                            = "Z1234567890ABC"
    name                               = "app.example.com"
    type                               = "TXT"
    records                            = [join("", [for i in range(510) : "a"])]
    set_identifier                     = "default"
    geolocation_routing_policy_country = "*"
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
