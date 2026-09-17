mock_provider "aws" {
  mock_resource "aws_drs_replication_configuration_template" {
    defaults = {
      id       = "dtpl-abcd1234"
      arn      = "arn:aws:drs:us-east-1:123456789012:replication-configuration-template/dtpl-abcd1234"
      tags_all = {}
    }
  }
}

run "single_template_baseline_plans_successfully" {
  command = plan

  variables {
    templates = {
      app1 = {
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
      }
    }
  }

  assert {
    condition     = aws_drs_replication_configuration_template.this["app1"].data_plane_routing == "PRIVATE_IP"
    error_message = "data_plane_routing should default to PRIVATE_IP."
  }

  assert {
    condition     = aws_drs_replication_configuration_template.this["app1"].create_public_ip == false
    error_message = "create_public_ip should default to false."
  }

  assert {
    condition     = aws_drs_replication_configuration_template.this["app1"].associate_default_security_group == false
    error_message = "associate_default_security_group should default to false."
  }

  assert {
    condition     = aws_drs_replication_configuration_template.this["app1"].auto_replicate_new_disks == true
    error_message = "auto_replicate_new_disks should default to true."
  }

  assert {
    condition     = aws_drs_replication_configuration_template.this["app1"].default_large_staging_disk_type == "GP3"
    error_message = "default_large_staging_disk_type should default to GP3."
  }

  assert {
    condition     = aws_drs_replication_configuration_template.this["app1"].ebs_encryption == "DEFAULT"
    error_message = "ebs_encryption should default to DEFAULT when no ebs_encryption_key_arn is supplied."
  }

  assert {
    condition     = aws_drs_replication_configuration_template.this["app1"].replication_server_instance_type == "t3.small"
    error_message = "replication_server_instance_type should default to t3.small."
  }

  assert {
    condition     = aws_drs_replication_configuration_template.this["app1"].use_dedicated_replication_server == false
    error_message = "use_dedicated_replication_server should default to false."
  }

  assert {
    condition     = aws_drs_replication_configuration_template.this["app1"].staging_area_tags["Name"] == "app1"
    error_message = "staging_area_tags should default to include a Name tag matching the map key."
  }

  assert {
    condition     = aws_drs_replication_configuration_template.this["app1"].tags["Name"] == "app1"
    error_message = "tags should default to include a Name tag matching the map key."
  }

  assert {
    condition     = length(aws_drs_replication_configuration_template.this["app1"].pit_policy) == 3
    error_message = "pit_policy should default to the three AWS-mandated rules."
  }

  assert {
    condition     = output.arns["app1"] != null
    error_message = "arns output should expose the mocked template ARN keyed by app1."
  }

  assert {
    condition     = output.ids["app1"] != null
    error_message = "ids output should expose the mocked template ID keyed by app1."
  }

  assert {
    condition     = output.ebs_encryption["app1"] == "DEFAULT"
    error_message = "ebs_encryption output should reflect the resolved DEFAULT encryption mode."
  }

  assert {
    condition     = output.templates["app1"] != null
    error_message = "templates output should expose the full resource map keyed by app1."
  }
}

run "multi_template_fan_out_creates_one_resource_per_entry" {
  command = plan

  variables {
    templates = {
      app1 = {
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
      }
      app2 = {
        replication_servers_security_groups_ids = ["sg-efgh5678"]
        staging_area_subnet_id                  = "subnet-efgh5678"
      }
    }
  }

  assert {
    condition     = length(output.arns) == 2
    error_message = "Expected the for_each over templates to fan out into exactly two templates."
  }
}

run "custom_ebs_encryption_key_arn_switches_encryption_to_custom" {
  command = plan

  variables {
    templates = {
      app1 = {
        ebs_encryption_key_arn                  = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-1234-1234-1234-123456789012"
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
      }
    }
  }

  assert {
    condition     = aws_drs_replication_configuration_template.this["app1"].ebs_encryption == "CUSTOM"
    error_message = "ebs_encryption should resolve to CUSTOM automatically when ebs_encryption_key_arn is supplied."
  }

  assert {
    condition     = aws_drs_replication_configuration_template.this["app1"].ebs_encryption_key_arn == "arn:aws:kms:us-east-1:123456789012:key/abcd1234-1234-1234-1234-123456789012"
    error_message = "ebs_encryption_key_arn should be passed through unchanged."
  }
}

run "associate_default_security_group_true_allows_empty_security_group_list" {
  command = plan

  variables {
    templates = {
      app1 = {
        associate_default_security_group = true
        staging_area_subnet_id           = "subnet-abcd1234"
      }
    }
  }

  assert {
    condition     = aws_drs_replication_configuration_template.this["app1"].associate_default_security_group == true
    error_message = "associate_default_security_group override should be honored."
  }

  assert {
    condition     = length(aws_drs_replication_configuration_template.this["app1"].replication_servers_security_groups_ids) == 0
    error_message = "An empty replication_servers_security_groups_ids list should be allowed when associate_default_security_group is true."
  }
}

run "rule_3_retention_duration_override_is_honored" {
  command = plan

  variables {
    templates = {
      app1 = {
        replication_servers_security_groups_ids = ["sg-abcd1234"]
        staging_area_subnet_id                  = "subnet-abcd1234"
        pit_policy = [
          {
            enabled            = true
            interval           = 10
            retention_duration = 60
            rule_id            = 1
            units              = "MINUTE"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 24
            rule_id            = 2
            units              = "HOUR"
          },
          {
            enabled            = true
            interval           = 1
            retention_duration = 14
            rule_id            = 3
            units              = "DAY"
          },
        ]
      }
    }
  }

  assert {
    condition     = [for rule in aws_drs_replication_configuration_template.this["app1"].pit_policy : rule.retention_duration if rule.rule_id == 3][0] == 14
    error_message = "Rule 3's retention_duration override should be honored, since it is the only mutable PIT policy value."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
