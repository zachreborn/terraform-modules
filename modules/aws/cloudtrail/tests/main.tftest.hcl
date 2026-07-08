mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "222222222222"
      arn        = "arn:aws:iam::222222222222:user/mock"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_organizations_organization" {
    defaults = {
      id                = "o-abcd1234"
      arn               = "arn:aws:organizations::333333333333:organization/o-abcd1234"
      master_account_id = "333333333333"
    }
  }

  mock_resource "aws_s3_bucket" {
    defaults = {
      id                 = "mock-cloudtrail-bucket"
      arn                = "arn:aws:s3:::mock-cloudtrail-bucket"
      bucket_domain_name = "mock-cloudtrail-bucket.s3.amazonaws.com"
      hosted_zone_id     = "Z3AQBSTGFYJSTF"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      key_id = "11111111-2222-3333-4444-555555555555"
      arn    = "arn:aws:kms:us-east-1:222222222222:key/11111111-2222-3333-4444-555555555555"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:222222222222:log-group:mock-cloudtrail-lg"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn  = "arn:aws:iam::222222222222:role/mock-cloudtrail-role"
      name = "mock-cloudtrail-role"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::222222222222:policy/mock-cloudtrail-policy"
    }
  }

  mock_resource "aws_cloudtrail" {
    defaults = {
      id          = "mock-cloudtrail"
      arn         = "arn:aws:cloudtrail:us-east-1:222222222222:trail/mock-cloudtrail"
      home_region = "us-east-1"
    }
  }
}

run "baseline_management_account_trail_plans_successfully" {
  command = plan

  variables {
    name                     = "cloudtrail"
    enable_s3_bucket_logging = false
  }

  assert {
    condition     = aws_cloudtrail.cloudtrail.name == "cloudtrail"
    error_message = "Expected the trail to be named 'cloudtrail'."
  }

  assert {
    condition     = strcontains(aws_s3_bucket_policy.cloudtrail_bucket_policy.policy, "arn:aws:cloudtrail:us-east-1:222222222222:trail/cloudtrail")
    error_message = "Management-account deployments (organization_management_account_id unset) should use the caller's own account ID in the trail ARN, preserving existing behavior."
  }
}

# When applied directly in the management account (rather than a delegated administrator account),
# DescribeOrganization's master_account_id naturally equals the caller's own account ID. This proves
# auto-detection still resolves correctly in that case, distinct from the delegated-admin scenario
# below where master_account_id and the caller account differ.
run "management_account_org_trail_resolves_own_account_id" {
  command = plan

  override_data {
    target = data.aws_organizations_organization.current
    values = {
      id                = "o-abcd1234"
      arn               = "arn:aws:organizations::222222222222:organization/o-abcd1234"
      master_account_id = "222222222222"
    }
  }

  variables {
    name                     = "organization"
    is_organization_trail    = true
    enable_s3_bucket_logging = false
  }

  assert {
    condition     = strcontains(aws_s3_bucket_policy.cloudtrail_bucket_policy.policy, "arn:aws:cloudtrail:us-east-1:222222222222:trail/organization")
    error_message = "When applied directly in the management account, the auto-detected master_account_id (equal to the caller's own account) must still produce a correct trail ARN."
  }
}

# Note: the mocked caller account (222222222222) is deliberately different from both the mocked
# master_account_id (333333333333, used by the auto-detection test below) and the explicit override
# used here (111111111111). If the module regressed to using the caller's own account ID for the
# trail ARN, every assertion in this run would fail.
run "delegated_admin_org_trail_explicit_override_takes_precedence" {
  command = plan

  variables {
    name                               = "delegated-cloudtrail"
    is_organization_trail              = true
    organization_management_account_id = "111111111111"
    enable_s3_bucket_logging           = false
  }

  assert {
    condition     = [for s in jsondecode(aws_s3_bucket_policy.cloudtrail_bucket_policy.policy).Statement : s if s.Sid == "AWSCloudTrailAclCheck"][0].Condition.StringEquals["AWS:SourceArn"] == "arn:aws:cloudtrail:us-east-1:111111111111:trail/delegated-cloudtrail"
    error_message = "An explicit organization_management_account_id override must take precedence over the auto-detected master_account_id."
  }

  assert {
    condition     = [for s in jsondecode(aws_s3_bucket_policy.cloudtrail_bucket_policy.policy).Statement : s if s.Sid == "AWSCloudTrailAccountIDWrite"][0].Resource == "${aws_s3_bucket.cloudtrail_s3_bucket.arn}/AWSLogs/111111111111/*"
    error_message = "The S3 bucket policy's AWSCloudTrailAccountIDWrite statement must write to the overridden management account's AWSLogs prefix."
  }

  assert {
    condition     = [for s in jsondecode(aws_s3_bucket_policy.cloudtrail_bucket_policy.policy).Statement : s if s.Sid == "AWSCloudTrailOrganizationWrite"][0].Condition.StringEquals["AWS:SourceArn"] == "arn:aws:cloudtrail:us-east-1:111111111111:trail/delegated-cloudtrail"
    error_message = "The S3 bucket policy's AWSCloudTrailOrganizationWrite statement must reference the overridden management account's trail ARN."
  }

  assert {
    condition     = [for s in jsondecode(aws_kms_key.cloudtrail.policy).Statement : s if s.Sid == "Enable IAM User Permissions"][0].Principal.AWS == "arn:aws:iam::222222222222:root"
    error_message = "The KMS key policy must still grant local key ownership to the caller (delegated administrator) account, not the management account."
  }

  assert {
    condition     = [for s in jsondecode(aws_kms_key.cloudtrail.policy).Statement : s if s.Sid == "Allow CloudTrail to encrypt logs"][0].Condition.StringEquals["aws:SourceArn"] == "arn:aws:cloudtrail:us-east-1:111111111111:trail/delegated-cloudtrail"
    error_message = "The KMS key policy's 'Allow CloudTrail to encrypt logs' statement must reference the overridden management account's trail ARN."
  }

  assert {
    condition     = [for s in jsondecode(aws_kms_key.cloudtrail.policy).Statement : s if s.Sid == "Allow principals in the account to decrypt log files"][0].Condition.StringEquals["kms:CallerAccount"] == "222222222222"
    error_message = "The KMS key policy's local-decrypt statement must still scope kms:CallerAccount to the caller (delegated administrator) account."
  }
}

# Proves auto-detection: no organization_management_account_id is set here, so the module must fall
# back to data.aws_organizations_organization.current.master_account_id (mocked as 333333333333)
# rather than the caller's own account (222222222222).
run "delegated_admin_org_trail_auto_detects_management_account_id" {
  command = plan

  variables {
    name                     = "delegated-cloudtrail"
    is_organization_trail    = true
    enable_s3_bucket_logging = false
  }

  assert {
    condition     = [for s in jsondecode(aws_s3_bucket_policy.cloudtrail_bucket_policy.policy).Statement : s if s.Sid == "AWSCloudTrailAclCheck"][0].Condition.StringEquals["AWS:SourceArn"] == "arn:aws:cloudtrail:us-east-1:333333333333:trail/delegated-cloudtrail"
    error_message = "Without an explicit override, the S3 bucket policy must reference the auto-detected master_account_id, not the caller (delegated administrator) account."
  }

  assert {
    condition     = [for s in jsondecode(aws_s3_bucket_policy.cloudtrail_bucket_policy.policy).Statement : s if s.Sid == "AWSCloudTrailAccountIDWrite"][0].Resource == "${aws_s3_bucket.cloudtrail_s3_bucket.arn}/AWSLogs/333333333333/*"
    error_message = "The S3 bucket policy's AWSCloudTrailAccountIDWrite statement must write to the auto-detected management account's AWSLogs prefix."
  }

  assert {
    condition     = [for s in jsondecode(aws_kms_key.cloudtrail.policy).Statement : s if s.Sid == "Allow CloudTrail to encrypt logs"][0].Condition.StringEquals["aws:SourceArn"] == "arn:aws:cloudtrail:us-east-1:333333333333:trail/delegated-cloudtrail"
    error_message = "The KMS key policy's 'Allow CloudTrail to encrypt logs' statement must reference the auto-detected management account's trail ARN."
  }

  assert {
    condition     = [for s in jsondecode(aws_kms_key.cloudtrail.policy).Statement : s if s.Sid == "Enable IAM User Permissions"][0].Principal.AWS == "arn:aws:iam::222222222222:root"
    error_message = "The KMS key policy must still grant local key ownership to the caller (delegated administrator) account, not the auto-detected management account."
  }
}

# Non-organization trails are always owned by the caller's own account; a stray
# organization_management_account_id override must be ignored since is_organization_trail is false.
run "non_organization_trail_ignores_management_account_id_override" {
  command = plan

  variables {
    name                               = "cloudtrail"
    is_organization_trail              = false
    organization_management_account_id = "999999999999"
    enable_s3_bucket_logging           = false
  }

  assert {
    condition     = strcontains(aws_s3_bucket_policy.cloudtrail_bucket_policy.policy, "arn:aws:cloudtrail:us-east-1:222222222222:trail/cloudtrail")
    error_message = "Non-organization trails must always use the caller's own account ID, ignoring any organization_management_account_id override."
  }
}

run "enable_s3_bucket_logging_true_creates_logging_resource" {
  command = plan

  variables {
    enable_s3_bucket_logging = true
    target_bucket            = "log-bucket"
  }

  assert {
    condition     = length(aws_s3_bucket_logging.cloudtrail_s3_bucket) == 1
    error_message = "Expected the S3 bucket logging resource to be planned when enable_s3_bucket_logging is true."
  }
}

run "enable_s3_bucket_logging_false_skips_logging_resource" {
  command = plan

  variables {
    enable_s3_bucket_logging = false
  }

  assert {
    condition     = length(aws_s3_bucket_logging.cloudtrail_s3_bucket) == 0
    error_message = "Expected no S3 bucket logging resource to be planned when enable_s3_bucket_logging is false."
  }
}
