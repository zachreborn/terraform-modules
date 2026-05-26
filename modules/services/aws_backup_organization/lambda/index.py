import boto3
import json
import os
import time
from botocore.exceptions import ClientError

def handler(event, context):
    """
    Lambda function to deploy backup vaults across organization accounts
    """
    
    try:
        accounts = event['accounts']
        vault_config = event['vault_config']
        
        results = []
        
        for account in accounts:
            account_id = account['id']
            account_name = account['name']
            
            print(f"Processing account: {account_name} ({account_id})")
            
            # Deploy to production region
            prod_result = deploy_vaults_to_account(
                account_id, 
                account_name,
                vault_config['prod_region'],
                vault_config,
                'prod'
            )
            
            # Deploy to DR region
            dr_result = deploy_vaults_to_account(
                account_id,
                account_name, 
                vault_config['dr_region'],
                vault_config,
                'dr'
            )
            
            results.append({
                'account_id': account_id,
                'account_name': account_name,
                'prod_region_result': prod_result,
                'dr_region_result': dr_result
            })
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Vault deployment completed',
                'results': results
            })
        }
        
    except Exception as e:
        print(f"Error in vault deployment: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': str(e)
            })
        }

def deploy_vaults_to_account(account_id, account_name, region, vault_config, region_type):
    """
    Deploy backup vaults to a specific account and region
    """
    
    try:
        # Determine which cross-account role to use
        cross_account_role = vault_config.get('cross_account_role', 'OrganizationAccountAccessRole')
        delegated_admin_account = vault_config.get('delegated_admin_account')
        
# Delegated admin account will not have vaults created (per requirements)
        
        # Assume role in target account
        sts_client = boto3.client('sts')
        
        try:
            assumed_role = sts_client.assume_role(
                RoleArn=f"arn:aws:iam::{account_id}:role/{cross_account_role}",
                RoleSessionName=f"BackupVaultDeployment-{account_id}"
            )
        except ClientError as e:
            if 'AccessDenied' in str(e):
                print(f"Access denied assuming role in account {account_id}. Trying alternative role names...")
                # Try alternative role names for delegated admin scenarios
                alternative_roles = [
                    'AWSControlTowerExecution', 
                    'BackupAdministratorRole',
                    'OrganizationAccountAccessRole'
                ]
                
                for alt_role in alternative_roles:
                    try:
                        assumed_role = sts_client.assume_role(
                            RoleArn=f"arn:aws:iam::{account_id}:role/{alt_role}",
                            RoleSessionName=f"BackupVaultDeployment-{account_id}"
                        )
                        print(f"Successfully assumed {alt_role} in account {account_id}")
                        break
                    except ClientError:
                        continue
                else:
                    raise Exception(f"Could not assume any role in account {account_id}")
            else:
                raise
        
        credentials = assumed_role['Credentials']
        
        # Create clients with assumed role credentials
        backup_client = boto3.client(
            'backup',
            region_name=region,
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken']
        )
        
        kms_client = boto3.client(
            'kms',
            region_name=region,
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken']
        )
        
        iam_client = boto3.client(
            'iam',
            region_name=region,
            aws_access_key_id=credentials['AccessKeyId'],
            aws_secret_access_key=credentials['SecretAccessKey'],
            aws_session_token=credentials['SessionToken']
        )
        
        # Create KMS key for backups
        kms_key_arn = create_backup_kms_key(kms_client, account_id, region, vault_config)
        
        # Create IAM role for backups
        create_backup_iam_role(iam_client, account_id)
        
        # Create backup vaults
        vault_results = []
        
        if region_type == 'prod':
            # Create production vaults
            vaults_to_create = [
                vault_config['vault_names']['hourly'],
                vault_config['vault_names']['daily'],
                vault_config['vault_names']['monthly']
            ]
        elif region_type == 'dr':
            # Create DR vault only in DR region
            vaults_to_create = [
                vault_config['vault_names']['dr']
            ]
        else:
            # Unknown region type
            print(f"Unknown region_type: {region_type}")
            vaults_to_create = []
        
        for vault_name in vaults_to_create:
            vault_result = create_backup_vault(
                backup_client, 
                vault_name, 
                kms_key_arn, 
                vault_config
            )
            vault_results.append(vault_result)
        
        return {
            'success': True,
            'region': region,
            'kms_key_arn': kms_key_arn,
            'vaults': vault_results
        }
        
    except Exception as e:
        print(f"Error deploying to account {account_id} in region {region}: {str(e)}")
        return {
            'success': False,
            'region': region,
            'error': str(e)
        }

def create_backup_kms_key(kms_client, account_id, region, vault_config):
    """
    Create KMS key for backup encryption
    """
    
    try:
        # Check if key already exists
        alias_name = f"alias/aws_backup_key_{region}"
        
        try:
            response = kms_client.describe_key(KeyId=alias_name)
            print(f"KMS key already exists: {response['KeyMetadata']['Arn']}")
            return response['KeyMetadata']['Arn']
        except ClientError as e:
            if e.response['Error']['Code'] != 'NotFoundException':
                raise
        
        # Create new key
        key_policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "Enable IAM User Permissions",
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": f"arn:aws:iam::{account_id}:root"
                    },
                    "Action": "kms:*",
                    "Resource": "*"
                },
                {
                    "Sid": "Allow AWS Backup to use the key",
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "backup.amazonaws.com"
                    },
                    "Action": [
                        "kms:Decrypt",
                        "kms:GenerateDataKey"
                    ],
                    "Resource": "*"
                }
            ]
        }
        
        response = kms_client.create_key(
            Description=vault_config['key_description'],
            KeyUsage='ENCRYPT_DECRYPT',
            CustomerMasterKeySpec='SYMMETRIC_DEFAULT',
            Policy=json.dumps(key_policy),
            Tags=[
                {
                    'TagKey': k,
                    'TagValue': v
                } for k, v in vault_config['tags'].items()
            ]
        )
        
        key_id = response['KeyMetadata']['KeyId']
        key_arn = response['KeyMetadata']['Arn']
        
        # Create alias
        kms_client.create_alias(
            AliasName=alias_name,
            TargetKeyId=key_id
        )
        
        # Enable key rotation
        kms_client.enable_key_rotation(KeyId=key_id)
        
        print(f"Created KMS key: {key_arn}")
        return key_arn
        
    except Exception as e:
        print(f"Error creating KMS key: {str(e)}")
        raise

def create_backup_iam_role(iam_client, account_id):
    """
    Create IAM role for AWS Backup service
    """
    
    try:
        role_name = 'aws_backup_role'
        
        # Check if role already exists
        try:
            response = iam_client.get_role(RoleName=role_name)
            print(f"IAM role already exists: {response['Role']['Arn']}")
            return response['Role']['Arn']
        except ClientError as e:
            if e.response['Error']['Code'] != 'NoSuchEntity':
                raise
        
        # Create role
        assume_role_policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "sts:AssumeRole",
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "backup.amazonaws.com"
                    }
                }
            ]
        }
        
        response = iam_client.create_role(
            RoleName=role_name,
            AssumeRolePolicyDocument=json.dumps(assume_role_policy),
            Description='Role for AWS Backup service'
        )
        
        role_arn = response['Role']['Arn']
        
        # Attach managed policies
        managed_policies = [
            'arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup',
            'arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores'
        ]
        
        for policy_arn in managed_policies:
            iam_client.attach_role_policy(
                RoleName=role_name,
                PolicyArn=policy_arn
            )
        
        # Wait for role to be available
        time.sleep(10)
        
        print(f"Created IAM role: {role_arn}")
        return role_arn
        
    except Exception as e:
        print(f"Error creating IAM role: {str(e)}")
        raise

def create_backup_vault(backup_client, vault_name, kms_key_arn, vault_config):
    """
    Create backup vault with policies and lock configuration
    """
    
    try:
        # Check if vault already exists
        try:
            response = backup_client.describe_backup_vault(BackupVaultName=vault_name)
            print(f"Backup vault already exists: {vault_name}")
            return {
                'vault_name': vault_name,
                'vault_arn': response['BackupVaultArn'],
                'already_exists': True
            }
        except ClientError as e:
            if e.response['Error']['Code'] != 'ResourceNotFoundException':
                raise
        
        # Create vault
        response = backup_client.create_backup_vault(
            BackupVaultName=vault_name,
            EncryptionKeyArn=kms_key_arn,
            BackupVaultTags=vault_config['tags']
        )
        
        vault_arn = response['BackupVaultArn']
        
        # Create vault access policy (deny delete)
        vault_policy = {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Sid": "DenyDeleteOperations",
                    "Effect": "Deny",
                    "Principal": {
                        "AWS": "*"
                    },
                    "Action": [
                        "backup:DeleteBackupVault",
                        "backup:DeleteRecoveryPoint",
                        "backup:UpdateRecoveryPointLifecycle"
                    ],
                    "Resource": vault_arn
                }
            ]
        }
        
        backup_client.put_backup_vault_access_policy(
            BackupVaultName=vault_name,
            Policy=json.dumps(vault_policy)
        )
        
        # Configure vault lock
        if vault_config.get('changeable_for_days'):
            backup_client.put_backup_vault_lock_configuration(
                BackupVaultName=vault_name,
                ChangeableForDays=vault_config['changeable_for_days']
            )
        
        print(f"Created backup vault: {vault_name}")
        return {
            'vault_name': vault_name,
            'vault_arn': vault_arn,
            'created': True
        }
        
    except Exception as e:
        print(f"Error creating backup vault {vault_name}: {str(e)}")
        return {
            'vault_name': vault_name,
            'error': str(e),
            'created': False
        }