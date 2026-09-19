mock_provider "aws" {
  mock_resource "aws_route53_zone" {
    defaults = {
      zone_id      = "Z1234567890EXAMPLE"
      name_servers = ["ns-1.awsdns-01.com", "ns-2.awsdns-02.org", "ns-3.awsdns-03.net", "ns-4.awsdns-04.co.uk"]
    }
  }
}

run "plan_succeeds_with_single_zone" {
  command = plan

  variables {
    zones = {
      "example.com" = {}
    }
  }

  assert {
    condition     = length(aws_route53_zone.zone) == 1
    error_message = "Expected exactly one zone to be planned."
  }

  assert {
    condition     = aws_route53_zone.zone["example.com"].name == "example.com"
    error_message = "Zone name should equal the map key."
  }
}

run "empty_zones_map_creates_no_zone" {
  command = plan

  variables {
    zones = {}
  }

  assert {
    condition     = length(aws_route53_zone.zone) == 0
    error_message = "An empty zones map should create zero zone resources."
  }
}

run "supports_multiple_zones" {
  command = plan

  variables {
    zones = {
      "example.com" = {}
      "example.net" = {}
    }
  }

  assert {
    condition     = length(aws_route53_zone.zone) == 2
    error_message = "Expected two zones to be planned for a two-entry zones map."
  }
}

run "optional_fields_default_to_null" {
  command = plan

  variables {
    zones = {
      "example.com" = {}
    }
  }

  assert {
    # NOTE: this asserts the module's own wiring (each.value.comment flows through
    # unmodified when the zones map entry omits comment), not the real AWS provider's
    # behavior. mock_provider does not run the provider's schema-level defaulting logic,
    # so this does not prove what a real (unmocked) plan/apply would produce -- the AWS
    # provider applies its own default of "Managed by Terraform" for aws_route53_zone.comment
    # when it is left unset, which is outside the scope of these offline tests.
    condition     = aws_route53_zone.zone["example.com"].comment == null
    error_message = "The module should pass through null (not inject its own default) for comment when the zones map entry omits it."
  }

  assert {
    condition     = aws_route53_zone.zone["example.com"].delegation_set_id == null
    error_message = "delegation_set_id should default to null when unset."
  }
}

run "optional_fields_honor_overrides" {
  command = plan

  variables {
    zones = {
      "example.com" = {
        comment           = "example.com zone"
        delegation_set_id = "N1PA6795SAMPLE"
      }
    }
  }

  assert {
    condition     = aws_route53_zone.zone["example.com"].comment == "example.com zone"
    error_message = "comment override should be honored."
  }

  assert {
    condition     = aws_route53_zone.zone["example.com"].delegation_set_id == "N1PA6795SAMPLE"
    error_message = "delegation_set_id override should be honored."
  }
}

run "tags_default_is_applied" {
  command = plan

  variables {
    zones = {
      "example.com" = {}
    }
  }

  assert {
    condition     = aws_route53_zone.zone["example.com"].tags["terraform"] == "true"
    error_message = "Default tags should include terraform = true (coerced to the string \"true\" by the resource's map(string) tags attribute)."
  }
}

run "tags_override_replaces_default" {
  command = plan

  variables {
    zones = {
      "example.com" = {}
    }
    tags = {
      team = "platform"
    }
  }

  assert {
    condition     = aws_route53_zone.zone["example.com"].tags["team"] == "platform"
    error_message = "tags override should be honored."
  }

  assert {
    condition     = !contains(keys(aws_route53_zone.zone["example.com"].tags), "terraform")
    error_message = "The tags variable is applied directly (not merged), so an override should fully replace the default map."
  }
}

run "outputs_expose_keyed_maps" {
  command = plan

  variables {
    zones = {
      "example.com" = {}
    }
  }

  assert {
    condition     = output.zone_ids["example.com"] == "Z1234567890EXAMPLE"
    error_message = "zone_ids output should map the zone name to its mocked zone_id."
  }

  assert {
    condition     = output.name_servers["example.com"][0] == "ns-1.awsdns-01.com"
    error_message = "name_servers output should map the zone name to its mocked name servers list."
  }
}
