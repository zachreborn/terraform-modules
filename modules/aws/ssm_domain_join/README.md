# ssm_domain_join

Automates Active Directory domain join for Windows EC2 instances using SSM State Manager and Secrets Manager. Any EC2 instance tagged with the configured key/value is automatically joined to the target domain — no user data or baked-in credentials required.

## Overview

The module creates three resources:

- **`aws_ssm_document`** — a Command document with an idempotent PowerShell script that sets DNS, checks whether the instance is already joined, and if not, retrieves credentials from Secrets Manager and runs `Add-Computer`.
- **`aws_ssm_association`** — tag-targeted State Manager association that applies the document to any matching EC2 instance on launch (and retries on failure).
- **`aws_iam_role_policy`** — inline policy on the caller-provided instance role granting `secretsmanager:GetSecretValue` on the specified secret only.

## Usage

```hcl
module "ad_join_slfcu" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ssm_domain_join?ref=feature/ssm-domain-join"

  domain_name        = "slfcu.local"
  dns_servers        = ["10.212.1.37", "192.168.200.4", "192.168.200.14"]
  secret_arn         = aws_secretsmanager_secret.ad_join.arn
  instance_role_name = "ssm-role"
  target_tag_value   = "slfcu.local"

  tags = {
    terraform   = "true"
    environment = "prod"
    created_by  = "terraform"
  }
}
```

Tag any EC2 instance you want auto-joined:

```hcl
tags = {
  ad_join = "slfcu.local"
}
```

## Inputs

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `domain_name` | `string` | yes | — | FQDN of the domain to join, e.g. `slfcu.local`. |
| `dns_servers` | `list(string)` | yes | — | DC IPs the joined instance should use for DNS resolution. |
| `secret_arn` | `string` | yes | — | ARN of the Secrets Manager secret holding join credentials. JSON-shaped `{"username":"...","password":"..."}`. Cross-account ARNs supported. |
| `instance_role_name` | `string` | yes | — | Name of the EC2 IAM role to grant `secretsmanager:GetSecretValue` on `secret_arn`. |
| `target_tag_value` | `string` | yes | — | EC2 tag value used to opt instances into auto-join, e.g. `slfcu.local`. |
| `target_tag_key` | `string` | no | `"ad_join"` | EC2 tag key used to opt instances into auto-join. |
| `name` | `string` | no | `"ssm-domain-join"` | Name prefix for the SSM document and association. |
| `tags` | `map(any)` | no | `{}` | Tags applied to the SSM document. |

## Outputs

| Name | Description |
|---|---|
| `ssm_document_name` | The name of the SSM domain join document. |
| `ssm_document_arn` | The ARN of the SSM domain join document. |
| `ssm_association_id` | The ID of the SSM association. |

## Notes

- The SSM document is idempotent — if the instance is already joined, the script exits without making changes.
- The `instance_role_name` must already exist (e.g. created by the `session_manager` module). This module only attaches a single inline policy statement to it.
- To opt an EC2 instance into auto-join, add the tag `ad_join = "slfcu.local"` (or whatever `target_tag_key`/`target_tag_value` values you configure).
- Cross-account secret access works without additional configuration in this module — the IAM policy evaluates against the secret's account at access time. The secret's resource policy must grant access to the spoke account's instance role.
- This module is Windows-only. The PowerShell document uses `Add-Computer` and `Get-WmiObject`, which are not available on Linux.
