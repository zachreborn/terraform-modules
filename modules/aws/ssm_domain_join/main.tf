# Terraform module which automates Active Directory domain join for EC2 instances via SSM.
#
# https://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-state-assoc.html

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

resource "aws_ssm_document" "default" {
  name            = var.name
  document_type   = "Command"
  document_format = "JSON"
  tags            = merge({ "Name" = var.name }, var.tags)

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
}

resource "aws_ssm_association" "default" {
  name = aws_ssm_document.default.name

  targets {
    key    = "tag:${var.target_tag_key}"
    values = [var.target_tag_value]
  }

  parameters = {
    DomainName = var.domain_name
    DnsServers = join(",", var.dns_servers)
    SecretArn  = var.secret_arn
  }
}

resource "aws_iam_role_policy" "secret_read" {
  name = "${var.name}-secret-read"
  role = var.instance_role_name

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
}
