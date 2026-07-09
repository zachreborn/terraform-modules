mock_provider "aws" {
  mock_resource "aws_secretsmanager_secret" {
    defaults = {
      id  = "arn:aws:secretsmanager:us-east-1:123456789012:secret:mock-abcdef"
      arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:mock-abcdef"
    }
  }

  mock_resource "aws_secretsmanager_secret_version" {
    defaults = {
      secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:mock-abcdef"
      version_id = "00000000-0000-0000-0000-000000000000"
    }
  }

  mock_resource "aws_secretsmanager_secret_rotation" {
    defaults = {
      rotation_enabled = true
    }
  }

  mock_resource "aws_secretsmanager_secret_policy" {
    defaults = {
      id = "arn:aws:secretsmanager:us-east-1:123456789012:secret:mock-abcdef"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      key_id = "mock-kms-key-id"
      arn    = "arn:aws:kms:us-east-1:123456789012:key/mock-kms-key-id"
    }
  }

  mock_resource "aws_kms_alias" {
    defaults = {
      arn = "arn:aws:kms:us-east-1:123456789012:alias/mock-kms-alias"
    }
  }
}

run "creates_secret_without_optional_resources" {
  command = plan

  variables {
    secrets = {
      database_credentials = {
        description = "test secret"
      }
    }
  }

  assert {
    condition     = length(aws_secretsmanager_secret.this) == 1
    error_message = "Expected exactly one secret to be planned."
  }

  assert {
    condition     = length(aws_secretsmanager_secret_version.this) == 0
    error_message = "Expected no secret versions without secret_values."
  }

  assert {
    condition     = length(aws_secretsmanager_secret_rotation.this) == 0
    error_message = "Expected no rotation resources without enable_rotation."
  }

  assert {
    condition     = length(aws_secretsmanager_secret_policy.this) == 0
    error_message = "Expected no policy resources without manage_resource_policy."
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "Expected no composed KMS keys without create_kms_key."
  }

  assert {
    condition     = output.arns["database_credentials"] != null
    error_message = "Expected the arns output to include the planned secret."
  }

  assert {
    condition     = output.ids["database_credentials"] != null
    error_message = "Expected the ids output to include the planned secret."
  }

  assert {
    condition     = length(output.rotation_enabled) == 0
    error_message = "Expected the rotation_enabled output to be empty without enable_rotation."
  }

  assert {
    condition     = length(output.kms_key_arns) == 0
    error_message = "Expected the kms_key_arns output to be empty without create_kms_key."
  }
}

run "creates_secret_version_when_value_provided" {
  command = plan

  variables {
    secrets = {
      database_credentials = {}
    }
    secret_values = {
      database_credentials = {
        secret_string = "placeholder"
      }
    }
  }

  assert {
    condition     = length(aws_secretsmanager_secret_version.this) == 1
    error_message = "Expected exactly one secret version to be planned."
  }

  assert {
    condition     = output.version_ids["database_credentials"] != null
    error_message = "Expected the version_ids output to include the planned secret version."
  }
}

run "ignores_secret_values_entry_without_matching_secret" {
  command = plan

  variables {
    secrets = {
      database_credentials = {}
    }
    secret_values = {
      unrelated_entry = {
        secret_string = "placeholder"
      }
    }
  }

  assert {
    condition     = length(aws_secretsmanager_secret_version.this) == 0
    error_message = "Expected secret_values entries without a matching secrets key to be ignored."
  }
}

run "composes_kms_key_and_wires_arn_into_secret" {
  command = plan

  variables {
    secrets = {
      database_credentials = {
        create_kms_key = true
      }
    }
  }

  assert {
    condition     = length(module.kms_key) == 1
    error_message = "Expected exactly one composed KMS key to be planned."
  }

  assert {
    condition     = aws_secretsmanager_secret.this["database_credentials"].kms_key_id == module.kms_key["database_credentials"].arn
    error_message = "Expected the secret to use the composed KMS key's ARN."
  }

  assert {
    condition     = output.kms_key_arns["database_credentials"] == module.kms_key["database_credentials"].arn
    error_message = "Expected the kms_key_arns output to expose the composed KMS key's ARN."
  }
}

run "creates_rotation_resource_when_enabled" {
  command = plan

  variables {
    secrets = {
      database_credentials = {
        enable_rotation                   = true
        rotation_lambda_arn               = "arn:aws:lambda:us-east-1:123456789012:function:rotate"
        rotation_automatically_after_days = 30
      }
    }
  }

  assert {
    condition     = length(aws_secretsmanager_secret_rotation.this) == 1
    error_message = "Expected exactly one rotation resource to be planned."
  }

  assert {
    condition     = output.rotation_enabled["database_credentials"] == true
    error_message = "Expected the rotation_enabled output to report true for the rotated secret."
  }
}

run "creates_resource_policy_when_managed" {
  command = plan

  variables {
    secrets = {
      database_credentials = {
        manage_resource_policy = true
        resource_policy = jsonencode({
          Version = "2012-10-17"
          Statement = [{
            Sid       = "AllowAccountRoot"
            Effect    = "Allow"
            Principal = { AWS = "arn:aws:iam::123456789012:root" }
            Action    = "secretsmanager:GetSecretValue"
            Resource  = "*"
          }]
        })
      }
    }
  }

  assert {
    condition     = length(aws_secretsmanager_secret_policy.this) == 1
    error_message = "Expected exactly one resource policy to be planned."
  }
}

run "replicates_secret_to_additional_regions" {
  command = plan

  variables {
    secrets = {
      multi_region_secret = {
        replica = [
          { region = "us-west-2" }
        ]
      }
    }
  }

  assert {
    condition     = length(aws_secretsmanager_secret.this["multi_region_secret"].replica) == 1
    error_message = "Expected exactly one replica block to be planned."
  }
}
