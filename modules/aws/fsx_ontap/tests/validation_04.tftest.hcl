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



# ---- Precondition failures (main.tf lifecycle) ----

run "rejects_byo_kms_key_without_kms_key_id" {
  command = plan
  variables {
    create_kms_key = false
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_both_throughput_options_set" {
  command = plan
  variables {
    throughput_capacity             = 512
    throughput_capacity_per_ha_pair = 512
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_neither_throughput_option_set" {
  command = plan
  variables {
    throughput_capacity             = null
    throughput_capacity_per_ha_pair = null
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_multi_az_with_single_subnet" {
  command = plan
  variables {
    subnet_ids = ["subnet-0a1b2c3d"]
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_single_az_with_two_subnets" {
  command = plan
  variables {
    deployment_type = "SINGLE_AZ_1"
    subnet_ids      = ["subnet-0a1b2c3d", "subnet-4e5f6a7b"]
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

# route_table_ids and endpoint_ip_address_range are documented as "(Multi-AZ only)" by the
# CreateFileSystemOntapConfiguration API reference; AWS returns a 400 for either on a
# SINGLE_AZ deployment type.
run "rejects_route_table_ids_on_single_az" {
  command = plan
  variables {
    deployment_type     = "SINGLE_AZ_1"
    subnet_ids          = ["subnet-0a1b2c3d"]
    preferred_subnet_id = "subnet-0a1b2c3d"
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_endpoint_ip_address_range_on_single_az" {
  command = plan
  variables {
    deployment_type           = "SINGLE_AZ_1"
    subnet_ids                = ["subnet-0a1b2c3d"]
    preferred_subnet_id       = "subnet-0a1b2c3d"
    route_table_ids           = null
    endpoint_ip_address_range = "203.0.113.0/24"
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

run "rejects_non_hex_subnet_id" {
  command = plan
  variables { subnet_ids = ["subnet-0a1b2c3d", "subnet-nothexvalue"] }
  expect_failures = [var.subnet_ids]
}

run "rejects_malformed_preferred_subnet_id" {
  command = plan
  variables { preferred_subnet_id = "sn-0a1b2c3d" }
  expect_failures = [var.preferred_subnet_id]
}

run "rejects_malformed_route_table_id" {
  command = plan
  variables { route_table_ids = ["route-table-0123456789abcdef0"] }
  expect_failures = [var.route_table_ids]
}