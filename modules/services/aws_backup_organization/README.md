# AWS Backup Organization Module

This module provides organization-wide AWS Backup management for multi-account environments. It deploys backup vaults across all organization accounts while managing policies centrally from the backup management account.

## Key Features

- **Organization-wide backup policies** managed centrally
- **Distributed vault deployment** across all member accounts
- **Cross-account backup copying** to disaster recovery regions
- **Automated vault lifecycle management** with Lambda functions
- **Comprehensive monitoring** and alerting
- **Tag-based resource selection** for flexible backup targeting
- **EventBridge integration** for automatic deployment to new accounts

## Architecture Overview

This module implements a hybrid approach to AWS Backup in Organizations:

1. **Central Policy Management**: Backup policies created from management/delegated admin account
2. **Distributed Vault Storage**: Backup vaults created in each member account
3. **Cross-Region Replication**: Daily backups automatically copied to DR regions
4. **Lambda-Based Deployment**: Deploys vaults via cross-account roles with fallback options
5. **Event-Driven Updates**: Automatically deploys to new organization accounts

## Requirements

- AWS Organizations must be enabled
- Must be deployed from organization management account or delegated backup admin account
- Member accounts need cross-account role (OrganizationAccountAccessRole, AWSControlTowerExecution, or BackupAdministratorRole)
- AWS Backup enabled as trusted service in organization
- CloudTrail enabled for EventBridge organization change detection

## Usage

### Basic Example

```hcl
module "organization_backup" {
  source = "github.com/zachreborn/terraform-modules//modules/services/aws_backup_organization"

  aws_prod_region = "us-west-2"
  aws_dr_region   = "us-east-2"

  tags = {
    environment = "prod"
    created_by  = "terraform"
    service     = "backups"
  }
}
```

### Delegated Admin Example

```hcl
module "organization_backup" {
  source = "github.com/zachreborn/terraform-modules//modules/services/aws_backup_organization"

  aws_prod_region = "us-west-2"
  aws_dr_region   = "us-east-2"

  # For delegated admin accounts
  cross_account_role_name = "BackupAdministratorRole"

  tags = {
    environment = "prod"
    created_by  = "Jake Jones"
    service     = "backups"
    priority    = "critical"
  }
}
```

## How It Works

### Lambda Execution Frequency
- **Initial Deployment**: Runs once during Terraform apply
- **New Accounts**: Automatically triggered via EventBridge when new accounts join organization
- **Manual Trigger**: Can be invoked manually via AWS Console/CLI

### Vault Deployment Logic
- **Production Region**: Creates hourly, daily, and monthly vaults in each account
- **DR Region**: Creates only disaster recovery vault in each account
- **Delegated Admin Account**: Skipped (vaults managed separately)

## Resource Tagging for Backups

```hcl
resource "aws_instance" "example" {
  # ... other configuration ...

  tags = {
    backup = "true"  # Include in backups
  }
}
```

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->