# Lambda Deployment Package

This directory contains the pre-packaged Lambda function for cross-account backup vault deployment.

## Files

- `vault_deployment.zip` - Pre-packaged deployment artifact for Terraform
- `index.py` - Python source code for the Lambda function (for reference)

## Updating the Lambda Function

To update the Lambda function:

1. Modify `index.py` with your changes
2. Recreate the ZIP package:

   ```bash
   cd lambda/
   zip vault_deployment.zip index.py
   ```
3. Commit both files to version control

## Function Overview

The Lambda function handles automated deployment of backup vaults across organization accounts by:

- Discovering all active organization accounts
- Assuming cross-account roles (OrganizationAccountAccessRole, AWSControlTowerExecution, or BackupAdministratorRole)
- Creating KMS keys for backup encryption in each account
- Creating IAM roles for AWS Backup service
- Deploying backup vaults (production and DR) to each account
- Configuring vault policies and lock settings