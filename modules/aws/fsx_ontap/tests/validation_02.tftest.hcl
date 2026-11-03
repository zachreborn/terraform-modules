mock_provider "aws" {
  mock_resource "aws_fsx_ontap_file_system" {
    defaults = {
      id  = "fs-0123456789abcdef0"
      arn = "arn:aws:fsx:us-east-1:123456789012:file-system/fs-0123456789abcdef0"
    }
  }

  mock_resource "aws_fsx_ontap_storage_virtual_machine" {
    defaults = {
      id = "svm-0123456789abcdef0"
    }
  }

  mock_resource "aws_fsx_ontap_volume" {
    defaults = {
      id = "fsvol-0123456789abcdef0"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      id     = "1234abcd-12ab-34cd-56ef-1234567890ab"
      key_id = "1234abcd-12ab-34cd-56ef-1234567890ab"
      arn    = "arn:aws:kms:us-east-1:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    }
  }

  mock_resource "aws_kms_alias" {
    defaults = {
      id = "alias/fsx_ontap-abcd1234"
    }
  }
}

# A valid MULTI_AZ_1 baseline so that only the variable/precondition under test fails.
variables {
  name                = "corp-ontap"
  storage_capacity    = 2048
  deployment_type     = "MULTI_AZ_1"
  subnet_ids          = ["subnet-0a1b2c3d", "subnet-4e5f6a7b"]
  preferred_subnet_id = "subnet-0a1b2c3d"
  route_table_ids     = ["rtb-0123456789abcdef0"]
  throughput_capacity = 512
}



# Values inside the API range but not valid for the deployment type are caught by the
# precondition rather than the variable validation, because the valid set depends on
# deployment_type and ha_pairs.
run "rejects_throughput_capacity_not_valid_for_the_deployment_type" {
  command = plan
  variables { throughput_capacity = 100 }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_gen2_throughput_on_a_gen1_deployment_type" {
  command = plan
  variables {
    deployment_type     = "MULTI_AZ_1"
    throughput_capacity = 3072
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_gen1_throughput_on_a_gen2_deployment_type" {
  command = plan
  variables {
    deployment_type     = "MULTI_AZ_2"
    throughput_capacity = 512
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

# 384 is valid only for MULTI_AZ_2. The previous flat validation rejected it outright, which
# made a supported configuration unreachable.
run "accepts_multi_az_2_only_throughput_value" {
  command = plan
  variables {
    deployment_type     = "MULTI_AZ_2"
    throughput_capacity = 384
  }

  assert {
    condition     = aws_fsx_ontap_file_system.this.throughput_capacity == 384
    error_message = "Expected 384 MB/s to be accepted on MULTI_AZ_2."
  }
}

run "rejects_invalid_throughput_capacity_per_ha_pair" {
  command = plan
  variables {
    throughput_capacity             = null
    throughput_capacity_per_ha_pair = 100
  }
  expect_failures = [var.throughput_capacity_per_ha_pair]
}

run "rejects_per_ha_pair_throughput_not_valid_for_the_deployment_type" {
  command = plan
  variables {
    deployment_type                 = "SINGLE_AZ_2"
    subnet_ids                      = ["subnet-0a1b2c3d"]
    route_table_ids                 = null
    throughput_capacity             = null
    throughput_capacity_per_ha_pair = 512
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

# throughput_capacity shares the provider's fixed, ha_pairs-agnostic set of valid values with
# throughput_capacity_per_ha_pair (see main.tf), so it cannot express a genuine multi-HA-pair
# total even when the total happens to divide evenly into a valid per-pair value.
run "rejects_total_throughput_capacity_with_multiple_ha_pairs" {
  command = plan
  variables {
    deployment_type     = "SINGLE_AZ_2"
    subnet_ids          = ["subnet-0a1b2c3d"]
    route_table_ids     = null
    ha_pairs            = 2
    throughput_capacity = 3072
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_a_total_that_does_not_divide_evenly_by_ha_pairs" {
  command = plan
  variables {
    deployment_type     = "SINGLE_AZ_2"
    subnet_ids          = ["subnet-0a1b2c3d"]
    route_table_ids     = null
    ha_pairs            = 5
    throughput_capacity = 3072
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_multiple_ha_pairs_on_a_deployment_type_that_does_not_support_them" {
  command = plan
  variables {
    ha_pairs            = 2
    throughput_capacity = 512
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_invalid_weekly_maintenance_start_time" {
  command = plan
  variables { weekly_maintenance_start_time = "8:99:00" }
  expect_failures = [var.weekly_maintenance_start_time]
}