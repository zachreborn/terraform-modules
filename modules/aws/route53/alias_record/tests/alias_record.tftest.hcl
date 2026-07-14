mock_provider "aws" {
  mock_resource "aws_route53_record" {
    defaults = {
      id = "Z1234567890EXAMPLE_www.example.com_A"
    }
  }
}

run "plan_succeeds_with_valid_alias_record" {
  command = plan

  variables {
    zone_id                      = "Z1234567890EXAMPLE"
    name                         = "www.example.com"
    type                         = "A"
    alias_name                   = "d123456abcdef8.cloudfront.net"
    alias_zone_id                = "Z2FDTNDATAQYW2"
    alias_evaluate_target_health = false
  }

  assert {
    condition     = aws_route53_record.this.zone_id == "Z1234567890EXAMPLE"
    error_message = "zone_id should pass through unchanged."
  }

  assert {
    condition     = aws_route53_record.this.name == "www.example.com"
    error_message = "name should pass through unchanged."
  }

  assert {
    condition     = aws_route53_record.this.type == "A"
    error_message = "type should pass through unchanged."
  }
}

run "set_identifier_and_health_check_id_default_to_null" {
  command = plan

  variables {
    zone_id                      = "Z1234567890EXAMPLE"
    name                         = "www.example.com"
    type                         = "A"
    alias_name                   = "d123456abcdef8.cloudfront.net"
    alias_zone_id                = "Z2FDTNDATAQYW2"
    alias_evaluate_target_health = false
  }

  assert {
    condition     = aws_route53_record.this.set_identifier == null
    error_message = "set_identifier should default to null when unset."
  }

  assert {
    condition     = aws_route53_record.this.health_check_id == null
    error_message = "health_check_id should default to null when unset."
  }
}

run "set_identifier_and_health_check_id_overrides_are_honored" {
  command = plan

  variables {
    zone_id                      = "Z1234567890EXAMPLE"
    name                         = "www.example.com"
    type                         = "A"
    set_identifier               = "primary"
    health_check_id              = "abcd1234-ab12-cd34-ef56-abcdef123456"
    alias_name                   = "d123456abcdef8.cloudfront.net"
    alias_zone_id                = "Z2FDTNDATAQYW2"
    alias_evaluate_target_health = false
  }

  assert {
    condition     = aws_route53_record.this.set_identifier == "primary"
    error_message = "set_identifier override should be honored."
  }

  assert {
    condition     = aws_route53_record.this.health_check_id == "abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "health_check_id override should be honored."
  }
}

run "alias_block_fields_pass_through" {
  command = plan

  variables {
    zone_id                      = "Z1234567890EXAMPLE"
    name                         = "www.example.com"
    type                         = "A"
    alias_name                   = "d123456abcdef8.cloudfront.net"
    alias_zone_id                = "Z2FDTNDATAQYW2"
    alias_evaluate_target_health = true
  }

  assert {
    condition     = aws_route53_record.this.alias[0].name == "d123456abcdef8.cloudfront.net"
    error_message = "alias.name should pass through unchanged."
  }

  assert {
    condition     = aws_route53_record.this.alias[0].zone_id == "Z2FDTNDATAQYW2"
    error_message = "alias.zone_id should pass through unchanged."
  }

  assert {
    condition     = aws_route53_record.this.alias[0].evaluate_target_health == true
    error_message = "alias.evaluate_target_health should pass through unchanged."
  }
}
