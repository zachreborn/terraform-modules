mock_provider "aws" {
  mock_resource "aws_route53_record" {
    defaults = {
      id = "Z1234567890EXAMPLE_www.example.com_A"
    }
  }
}

run "plan_succeeds_with_valid_record" {
  command = plan

  variables {
    zone_id = "Z1234567890EXAMPLE"
    name    = "www.example.com"
    type    = "TXT"
    records = ["sample-txt-value"]
  }

  assert {
    condition     = contains(aws_route53_record.this.records, "sample-txt-value")
    error_message = "Short records should pass through unchanged."
  }

  assert {
    condition     = aws_route53_record.this.ttl == 300
    error_message = "ttl should default to 300."
  }
}

run "ttl_override_is_honored" {
  command = plan

  variables {
    zone_id = "Z1234567890EXAMPLE"
    name    = "www.example.com"
    type    = "TXT"
    records = ["sample-txt-value"]
    ttl     = 60
  }

  assert {
    condition     = aws_route53_record.this.ttl == 60
    error_message = "ttl override should be honored."
  }
}

run "health_check_id_defaults_to_null" {
  command = plan

  variables {
    zone_id = "Z1234567890EXAMPLE"
    name    = "www.example.com"
    type    = "TXT"
    records = ["sample-txt-value"]
  }

  assert {
    condition     = aws_route53_record.this.health_check_id == null
    error_message = "health_check_id should default to null when unset."
  }
}

run "health_check_id_override_is_honored" {
  command = plan

  variables {
    zone_id         = "Z1234567890EXAMPLE"
    name            = "www.example.com"
    type            = "TXT"
    records         = ["sample-txt-value"]
    health_check_id = "abcd1234-ab12-cd34-ef56-abcdef123456"
  }

  assert {
    condition     = aws_route53_record.this.health_check_id == "abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "health_check_id override should be honored."
  }
}

run "multiple_records_pass_through" {
  command = plan

  variables {
    zone_id = "Z1234567890EXAMPLE"
    name    = "www.example.com"
    type    = "TXT"
    records = ["v=spf1 include:example.com ~all", "second-record"]
  }

  assert {
    condition     = length(aws_route53_record.this.records) == 2
    error_message = "Expected both records to be planned."
  }
}

run "records_longer_than_255_characters_are_split" {
  command = plan

  variables {
    zone_id = "Z1234567890EXAMPLE"
    name    = "www.example.com"
    type    = "TXT"
    records = [join("", [for i in range(300) : "a"])]
  }

  assert {
    condition     = tolist(aws_route53_record.this.records)[0] == "${join("", [for i in range(255) : "a"])}\"\"${join("", [for i in range(45) : "a"])}"
    error_message = "A 300-character record should have an escaped-quote pair inserted immediately after the first 255 characters (per the AWS TXT-record chunking workaround), with the remaining 45 characters appended unchanged."
  }
}

# Boundary cases for issue #394: a record whose length is an exact multiple of 255 must NOT
# receive a trailing "" separator, because a separator only belongs *between* two chunks. Do
# NOT re-pin these to the old buggy `<255>""` / `<255>""<255>""` values -- if a case fails,
# fix the chunking `locals` in main.tf, not the assertion.
run "records_of_exactly_255_characters_pass_through_unchanged" {
  command = plan

  variables {
    zone_id = "Z1234567890EXAMPLE"
    name    = "www.example.com"
    type    = "TXT"
    records = [join("", [for i in range(255) : "a"])]
  }

  assert {
    condition     = tolist(aws_route53_record.this.records)[0] == join("", [for i in range(255) : "a"])
    error_message = "An exactly-255-character record should pass through unchanged with no trailing \"\" separator (fixes #394); it fits in a single 255-character chunk with nothing to split off."
  }

  assert {
    condition     = length(tolist(aws_route53_record.this.records)[0]) == 255
    error_message = "An exactly-255-character record must stay 255 characters long, not 257 (no trailing \"\" separator)."
  }
}

run "records_of_exactly_510_characters_get_one_separator_between_chunks" {
  command = plan

  variables {
    zone_id = "Z1234567890EXAMPLE"
    name    = "www.example.com"
    type    = "TXT"
    records = [join("", [for i in range(510) : "a"])]
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
