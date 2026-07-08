mock_provider "aws" {
  mock_resource "aws_cloudtrail_organization_delegated_admin_account" {
    defaults = {
      arn               = "arn:aws:organizations::111111111111:account/o-abcd1234/222222222222"
      email             = "audit@example.com"
      name              = "audit"
      service_principal = "cloudtrail.amazonaws.com"
    }
  }
}

run "registers_delegated_admin_with_given_account_id" {
  command = plan

  variables {
    account_id = "222222222222"
  }

  assert {
    condition     = aws_cloudtrail_organization_delegated_admin_account.this.account_id == "222222222222"
    error_message = "Expected the delegated administrator resource to be planned with the given account_id."
  }
}

run "rejects_invalid_account_id" {
  command = plan

  variables {
    account_id = "not-an-account-id"
  }

  expect_failures = [var.account_id]
}
