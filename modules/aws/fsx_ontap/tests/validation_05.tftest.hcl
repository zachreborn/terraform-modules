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



run "rejects_more_than_fifty_route_table_ids" {
  command = plan
  variables { route_table_ids = [for i in range(51) : format("rtb-%08x", i)] }
  expect_failures = [var.route_table_ids]
}

run "rejects_malformed_security_group_id" {
  command = plan
  variables { security_group_ids = ["sg-nothexvalue"] }
  expect_failures = [var.security_group_ids]
}

run "rejects_malformed_kms_key_id" {
  command = plan
  variables {
    create_kms_key = false
    kms_key_id     = "alias/corp-ontap"
  }
  expect_failures = [var.kms_key_id]
}

run "rejects_endpoint_ip_address_range_that_is_not_a_cidr" {
  command = plan
  variables { endpoint_ip_address_range = "198.19.0.1-198.19.0.64" }
  expect_failures = [var.endpoint_ip_address_range]
}

run "rejects_short_fsx_admin_password" {
  command = plan
  variables { fsx_admin_password = "short7c" } # gitleaks:allow
  expect_failures = [var.fsx_admin_password]
}

run "rejects_short_svm_admin_password" {
  command = plan
  variables {
    storage_virtual_machines = {
      smb = {
        svm_admin_password = "short7c" # gitleaks:allow
      }
    }
  }
  expect_failures = [var.storage_virtual_machines]
}

# Active Directory caps a computer object name at 15 characters.
run "rejects_netbios_name_longer_than_fifteen_characters" {
  command = plan
  variables {
    storage_virtual_machines = {
      smb = {
        svm_admin_password = "testpass1" # gitleaks:allow
        active_directory_configuration = {
          netbios_name = "CORP-ONTAP-SVM-01"
          self_managed_active_directory_configuration = {
            dns_ips     = ["10.11.1.100"]
            domain_name = "corp.example.com"
            username    = "FSxServiceAccount"
            password    = "testpass1" # gitleaks:allow
          }
        }
      }
    }
  }
  expect_failures = [var.storage_virtual_machines]
}

run "rejects_preferred_subnet_id_outside_subnet_ids" {
  command = plan
  variables {
    preferred_subnet_id = "subnet-99999999"
  }
  expect_failures = [aws_fsx_ontap_file_system.this]
}

# A mistyped storage_virtual_machine_key must surface as this precondition rather than a
# bare "Invalid index" raised while the volume's arguments are evaluated, which is why
# main.tf resolves the SVM through lookup() instead of indexing the resource directly.
run "rejects_volume_referencing_an_unknown_storage_virtual_machine_key" {
  command = plan
  variables {
    storage_virtual_machines = {
      smb = {
        svm_admin_password = "testpass" # gitleaks:allow
      }
    }
    volumes = {
      data = {
        storage_virtual_machine_key = "typo"
        junction_path               = "/data"
        size_in_megabytes           = 1024
      }
    }
  }
  expect_failures = [aws_fsx_ontap_volume.this]
}

# Do NOT delete, skip, or loosen an expect_failures case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# validation {} / precondition {} block in variables.tf / main.tf has a bug, or the test's
# inputs are wrong -- find and fix the root cause, then re-run `tofu test` until it passes
# for the right reason.
