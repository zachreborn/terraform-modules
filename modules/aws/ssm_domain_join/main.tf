###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Data Sources
###########################

###########################
# Locals
###########################

###########################
# SSM Domain Join Document
###########################
resource "aws_ssm_document" "this" {
  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Idempotent AD domain join via Secrets Manager credentials"
    parameters = {
      DomainName = {
        type        = "String"
        description = "FQDN of the domain to join"
      }
      DnsServers = {
        type        = "StringList"
        description = "Domain controller IPs to set as DNS servers"
      }
      SecretArn = {
        type        = "String"
        description = "ARN of Secrets Manager secret with username and password keys"
      }
    }
    mainSteps = [
      {
        action = "aws:runPowerShellScript"
        name   = "DomainJoin"
        inputs = {
          runCommand = [
            "Set-DnsClientServerAddress -InterfaceAlias 'Ethernet*' -ServerAddresses @('{{ DnsServers }}'.Split(','))",
            "if ((Get-WmiObject Win32_ComputerSystem).Domain -eq '{{ DomainName }}') { exit 0 }",
            "$sec  = (Get-SECSecretValue -SecretId '{{ SecretArn }}').SecretString | ConvertFrom-Json",
            "$cred = New-Object System.Management.Automation.PSCredential($sec.username, (ConvertTo-SecureString $sec.password -AsPlainText -Force))",
            "Add-Computer -DomainName '{{ DomainName }}' -Credential $cred -Restart -Force"
          ]
        }
      }
    ]
  })
  document_format = "JSON"
  document_type   = "Command"
  name            = var.name
  tags            = merge(tomap({ Name = var.name }), var.tags)
  target_type     = var.target_type
  version_name    = var.version_name

  permissions = var.permissions != null ? {
    account_ids = var.permissions.account_ids
    type        = var.permissions.type
  } : null
}

###########################
# SSM Association
###########################
resource "aws_ssm_association" "this" {
  apply_only_at_cron_interval = var.apply_only_at_cron_interval
  association_name            = var.association_name
  compliance_severity         = var.compliance_severity
  document_version            = var.document_version
  max_concurrency             = var.max_concurrency
  max_errors                  = var.max_errors
  name                        = aws_ssm_document.this.name
  parameters = {
    DomainName = var.domain_name
    DnsServers = join(",", var.dns_servers)
    SecretArn  = var.secret_arn
  }
  schedule_expression              = var.schedule_expression
  schedule_offset                  = var.schedule_offset
  sync_compliance                  = var.sync_compliance
  tags                             = var.tags
  wait_for_success_timeout_seconds = var.wait_for_success_timeout_seconds

  dynamic "output_location" {
    for_each = var.output_location_s3_bucket_name != null ? [1] : []
    content {
      s3_bucket_name = var.output_location_s3_bucket_name
      s3_key_prefix  = var.output_location_s3_key_prefix
      s3_region      = var.output_location_s3_region
    }
  }

  dynamic "targets" {
    for_each = var.targets
    content {
      key    = targets.value.key
      values = targets.value.values
    }
  }
}

###########################
# IAM
###########################
resource "aws_iam_role_policy" "secret_read" {
  name        = var.name_prefix == null ? "${var.name}-secret-read" : null
  name_prefix = var.name_prefix != null ? "${var.name_prefix}-secret-read" : null
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = var.secret_arn
      }
    ]
  })
  role = var.instance_role_name
}
