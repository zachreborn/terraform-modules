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
        type        = "String"
        description = "Comma-separated domain controller IPs to set as DNS servers"
      }
      SecretArn = {
        type        = "String"
        description = "ARN of Secrets Manager secret with username and password keys"
      }
      OUPath = {
        type        = "String"
        description = "Distinguished name of the OU to place the computer object in. Leave empty to use the default Computers container."
        default     = ""
      }
      CloudWatchLogGroup = {
        type        = "String"
        description = "CloudWatch Logs log group name for domain join output. Leave empty to disable CloudWatch logging."
        default     = ""
      }
    }
    mainSteps = [
      {
        action = "aws:runPowerShellScript"
        name   = "DomainJoin"
        inputs = {
          runCommand = [
            "$_cwlGroup  = '{{ CloudWatchLogGroup }}'",
            "$_cwlStream = ('{0}/{1}' -f $env:COMPUTERNAME, (Get-Date -Format 'yyyyMMdd-HHmmss'))",
            "if ($_cwlGroup) { try { New-CWLLogGroup -LogGroupName $_cwlGroup -ErrorAction SilentlyContinue; New-CWLLogStream -LogGroupName $_cwlGroup -LogStreamName $_cwlStream -ErrorAction SilentlyContinue } catch {} }",
            "function Write-Log { param([string]$Msg); $ts = [System.DateTime]::UtcNow; Write-Output ('[{0}] {1}' -f $ts.ToString('yyyy-MM-ddTHH:mm:ssZ'), $Msg); if (-not $script:_cwlGroup) { return }; try { $e = New-Object Amazon.CloudWatchLogs.Model.InputLogEvent; $e.Message = $Msg; $e.Timestamp = $ts; Write-CWLLogEvent -LogGroupName $script:_cwlGroup -LogStreamName $script:_cwlStream -LogEvent $e } catch {} }",
            "Write-Log 'Starting domain join'",
            "Write-Log 'Configuring DNS server addresses'",
            "Set-DnsClientServerAddress -InterfaceAlias 'Ethernet*' -ServerAddresses @('{{ DnsServers }}'.Split(','))",
            "Write-Log 'DNS configured; checking current domain membership'",
            "if ((Get-WmiObject Win32_ComputerSystem).Domain -eq '{{ DomainName }}') { Write-Log 'Already domain joined, exiting'; exit 0 }",
            "Write-Log 'Retrieving join credentials from Secrets Manager'",
            "$sec  = (Get-SECSecretValue -SecretId '{{ SecretArn }}').SecretString | ConvertFrom-Json",
            "Write-Log 'Credentials retrieved'",
            "$cred = New-Object System.Management.Automation.PSCredential($sec.username, (ConvertTo-SecureString $sec.password -AsPlainText -Force))",
            "Write-Log 'Joining domain {{ DomainName }}, system will restart'",
            "if ('{{ OUPath }}') { Add-Computer -DomainName '{{ DomainName }}' -OUPath '{{ OUPath }}' -Credential $cred -Restart -Force } else { Add-Computer -DomainName '{{ DomainName }}' -Credential $cred -Restart -Force }"
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
    DomainName         = var.domain_name
    DnsServers         = join(",", var.dns_servers)
    SecretArn          = var.secret_arn
    CloudWatchLogGroup = var.cloudwatch_log_group_name != null ? var.cloudwatch_log_group_name : ""
    OUPath             = var.ou_path != null ? var.ou_path : ""
  }
  schedule_expression              = var.schedule_expression
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
# CloudWatch Logs
###########################
resource "aws_cloudwatch_log_group" "domain_join" {
  count             = var.cloudwatch_log_group_name != null ? 1 : 0
  name              = var.cloudwatch_log_group_name
  retention_in_days = var.cloudwatch_log_retention_days
  tags              = merge(tomap({ Name = var.cloudwatch_log_group_name }), var.tags)
}

###########################
# IAM
###########################
resource "aws_iam_role_policy" "secret_read" {
  name        = var.name_prefix == null ? "${var.name}-secret-read" : null
  name_prefix = var.name_prefix != null ? "${var.name_prefix}-secret-read" : null
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect   = "Allow"
          Action   = "secretsmanager:GetSecretValue"
          Resource = var.secret_arn
        }
      ],
      var.kms_key_arn != null ? [
        {
          Effect   = "Allow"
          Action   = "kms:Decrypt"
          Resource = var.kms_key_arn
        }
      ] : []
    )
  })
  role = var.instance_role_name
}

resource "aws_iam_role_policy" "cloudwatch_logs" {
  count       = var.cloudwatch_log_group_name != null ? 1 : 0
  name        = var.name_prefix == null ? "${var.name}-cloudwatch-logs" : null
  name_prefix = var.name_prefix != null ? "${var.name_prefix}-cloudwatch-logs" : null
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:log-group:${var.cloudwatch_log_group_name}:*"
      }
    ]
  })
  role = var.instance_role_name
}
