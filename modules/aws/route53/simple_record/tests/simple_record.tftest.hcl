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

# BUG (tracked in https://github.com/zachreborn/terraform-modules/issues/394): the
# `replace(record, "/(.{255})/", "$1\"\"")` splitting regex in locals.records matches an
# exact multiple of 255 characters and appends a trailing, unnecessary "" separator even
# though there is no remaining content after it to separate from. The module's own comment
# says records are only split when "longer than 255 characters", so a record of exactly 255
# (or exactly 510, etc.) characters should arguably pass through with no trailing separator
# at all. These two runs pin the CURRENT (buggy) behavior so the suite documents reality --
# do not treat them as a specification. Update both runs when issue #394 is fixed.
run "records_of_exactly_255_characters_get_an_unwanted_trailing_separator" {
  command = plan

  variables {
    zone_id = "Z1234567890EXAMPLE"
    name    = "www.example.com"
    type    = "TXT"
    records = [join("", [for i in range(255) : "a"])]
  }

  assert {
    condition     = tolist(aws_route53_record.this.records)[0] == "${join("", [for i in range(255) : "a"])}\"\""
    error_message = "Known bug (#394): an exactly-255-character record currently gets a superfluous trailing \"\" separator appended, even though nothing follows it to split off."
  }
}

run "records_of_exactly_510_characters_get_an_unwanted_trailing_separator" {
  command = plan

  variables {
    zone_id = "Z1234567890EXAMPLE"
    name    = "www.example.com"
    type    = "TXT"
    records = [join("", [for i in range(510) : "a"])]
  }

  assert {
    condition     = tolist(aws_route53_record.this.records)[0] == "${join("", [for i in range(255) : "a"])}\"\"${join("", [for i in range(255) : "a"])}\"\""
    error_message = "Known bug (#394): an exactly-510-character record currently gets a superfluous trailing \"\" separator appended after the second 255-character chunk, even though nothing follows it to split off."
  }
}
