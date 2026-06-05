<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">SSM Domain Join</h3>
  <p align="center">
    Automates Active Directory domain join for Windows EC2 instances using SSM State Manager and Secrets Manager. Any EC2 instance matching the configured targets is automatically renamed to match its EC2 <code>Name</code> tag, optionally set to a specified time zone, and joined to the domain — all in a single reboot, with no user data or baked-in credentials required. If the desired name is already in DNS, the module increments the trailing number (e.g. <code>SERVER01</code> → <code>SERVER02</code>) to avoid collisions.
    <br />
    <a href="https://github.com/zachreborn/terraform-modules"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://zacharyhill.co">Zachary Hill</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Report Bug</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#architecture">Architecture</a></li>
    <li><a href="#cross-account-usage">Cross-Account Usage</a></li>
    <li><a href="#requirements">Requirements</a></li>
    <li><a href="#providers">Providers</a></li>
    <li><a href="#modules">Modules</a></li>
    <li><a href="#Resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

Tag-targeted domain join using a Secrets Manager secret for credentials.

```hcl
module "ad_join" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ssm_domain_join?ref=v0.0.1"

  domain_name        = "corp.example.com"
  dns_servers        = ["10.0.0.10", "10.0.0.11"]
  secret_arn         = aws_secretsmanager_secret.ad_join.arn
  instance_role_name = module.session_manager.iam_role_name
  timezone           = "Eastern Standard Time"

  targets = [
    {
      key    = "tag:ad_join"
      values = ["corp.example.com"]
    }
  ]

  tags = {
    terraform   = "true"
    environment = "prod"
  }
}
```

Tag any EC2 instance you want auto-joined. The `Name` tag value becomes the computer name:

```hcl
tags = {
  Name    = "WEBSVR01"
  ad_join = "corp.example.com"
}
```

### Scheduled Example

Run the association on a schedule rather than only on instance launch.

```hcl
module "ad_join_scheduled" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ssm_domain_join?ref=v0.0.1"

  domain_name        = "corp.example.com"
  dns_servers        = ["10.0.0.10", "10.0.0.11"]
  secret_arn         = aws_secretsmanager_secret.ad_join.arn
  instance_role_name = module.session_manager.iam_role_name
  timezone           = "Eastern Standard Time"

  schedule_expression         = "rate(1 hour)"
  apply_only_at_cron_interval = false
  compliance_severity         = "HIGH"

  targets = [
    {
      key    = "tag:ad_join"
      values = ["corp.example.com"]
    }
  ]

  tags = {
    terraform   = "true"
    environment = "prod"
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ARCHITECTURE -->

## Architecture

The diagram below shows the resources this module creates and how they interact with each other and with an example EC2 instance at runtime.

![Architecture Diagram](./architecture.svg)

| Step | What happens |
|------|-------------|
| 1 | SSM State Manager targets instances that carry the `ad_join` tag. |
| 2 | The association delivers the `aws_ssm_document` to the SSM Agent and triggers execution. |
| 3 | The inline IAM policy (`aws_iam_role_policy`) is attached to the instance's IAM role, granting `secretsmanager:GetSecretValue`, `kms:Decrypt` (if a KMS key is provided), and `ec2:DescribeTags`. |
| 4 | The script configures DNS server addresses on the instance. |
| 5 | If the instance is already domain-joined, the script exits — no further action is taken. |
| 6 | If `timezone` is set, `Set-TimeZone` applies the specified Windows time zone ID. |
| 7 | The SSM Agent calls `GetSecretValue` to retrieve the domain-join credentials from Secrets Manager. |
| 8 | The agent calls the EC2 metadata service (IMDSv2) to read the instance ID and region, then calls `ec2:DescribeTags` to retrieve the `Name` tag value. |
| 9 | The script checks DNS for the desired computer name. If a record already exists, it increments the trailing number (e.g. `SERVER01` → `SERVER02`) until an available name is found. |
| 10 | The agent runs `Add-Computer`, renaming the instance to the resolved name and joining it to the domain in a single reboot. |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CROSS-ACCOUNT USAGE -->

## Cross-Account Usage

A common topology is a central **hub** account that holds the domain-join credentials secret, with EC2 instances running in one or more **spoke** accounts. In that model you deploy this module **in each spoke** — it creates the SSM document, the State Manager association, and the inline policy on the instance role *locally* — while the secret and its KMS key stay in the hub and are read cross-account.

Cross-account access to a Secrets Manager secret encrypted with a customer-managed KMS key requires grants on **both** sides. This module handles only the spoke (identity) side; the hub-side grants are yours to add:

| Side | Grant | Provided by |
|------|-------|-------------|
| **Spoke** (instance role identity) | Inline policy: `secretsmanager:GetSecretValue` on `secret_arn`, `kms:Decrypt` on `kms_key_arn`, `ec2:DescribeTags` | **This module** — automatic when you pass `secret_arn` (and `kms_key_arn`) |
| **Hub** — secret resource policy | Allow the spoke role `secretsmanager:GetSecretValue` | You (hub account) |
| **Hub** — KMS key policy | Allow the spoke role `kms:Decrypt` | You (hub account) |

> [!WARNING]
> **Both hub grants are required.** If you add the secret resource policy but forget the KMS key policy, the spoke role will succeed at `GetSecretValue` and then **fail to decrypt** the secret value — the value is encrypted with the customer-managed key, and an identity-side `kms:Decrypt` grant is not sufficient without a matching key-policy grant. This failure mode is easy to miss because the secret metadata call succeeds.

> [!NOTE]
> **Apply ordering.** KMS key policies validate principals at apply time. Create the spoke instance role **before** applying the hub key-policy grant, or the hub apply fails with `MalformedPolicyDocument`. (Secret resource policies that name a spoke role principal have the same constraint.)

### Example

**Spoke account** — deploy the module pointing at the hub's secret and key ARNs:

```hcl
module "ad_join" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ssm_domain_join?ref=v0.0.1"

  domain_name        = "corp.example.com"
  dns_servers        = ["10.0.0.10", "10.0.0.11"]
  secret_arn         = "arn:aws:secretsmanager:us-west-2:111111111111:secret:ad-join-credentials-AbCdEf"
  kms_key_arn        = "arn:aws:kms:us-west-2:111111111111:key/00000000-0000-0000-0000-000000000000"
  instance_role_name = aws_iam_role.ssm_role.name # e.g. "ssm-role"

  targets = [
    {
      key    = "tag:ad_join"
      values = ["corp.example.com"]
    }
  ]

  tags = {
    terraform   = "true"
    environment = "test"
  }
}
```

**Hub account** — grant the spoke role on **both** the secret resource policy and the KMS key policy:

```hcl
# 1) Secret resource policy
resource "aws_secretsmanager_secret_policy" "ad_join" {
  secret_arn = aws_secretsmanager_secret.ad_join.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "SpokeRead"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::222222222222:role/ssm-role" }
        Action    = "secretsmanager:GetSecretValue"
        Resource  = "*"
      }
    ]
  })
}

# 2) KMS key policy — the easy-to-miss half
resource "aws_kms_key" "ad_join" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "RootAccountAccess"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::111111111111:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "SecretsManagerAccess"
        Effect    = "Allow"
        Principal = { Service = "secretsmanager.amazonaws.com" }
        Action    = ["kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
        Resource  = "*"
      },
      {
        Sid       = "SpokeDecrypt"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::222222222222:role/ssm-role" }
        Action    = "kms:Decrypt"
        Resource  = "*"
      }
    ]
  })
}
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- Run the command above to regenerate the Inputs/Outputs tables after any variable changes. -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role_policy.secret_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_ssm_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_association) | resource |
| [aws_ssm_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |

## Inputs

No inputs.

## Outputs

No outputs.
<!-- END_TF_DOCS -->

<!-- LICENSE -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->

## Contact

Zachary Hill - [![LinkedIn][linkedin-shield]][linkedin-url] - zhill@zacharyhill.co

Project Link: [https://github.com/zachreborn/terraform-modules](https://github.com/zachreborn/terraform-modules)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

- [Zachary Hill](https://zacharyhill.co)
- [Jake Jones](https://github.com/jakeasarus)
- [Brad Engberg](https://github.com/bradms98)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[contributors-shield]: https://img.shields.io/github/contributors/zachreborn/terraform-modules.svg?style=for-the-badge
[contributors-url]: https://github.com/zachreborn/terraform-modules/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/zachreborn/terraform-modules.svg?style=for-the-badge
[forks-url]: https://github.com/zachreborn/terraform-modules/network/members
[stars-shield]: https://img.shields.io/github/stars/zachreborn/terraform-modules.svg?style=for-the-badge
[stars-url]: https://github.com/zachreborn/terraform-modules/stargazers
[issues-shield]: https://img.shields.io/github/issues/zachreborn/terraform-modules.svg?style=for-the-badge
[issues-url]: https://github.com/zachreborn/terraform-modules/issues
[license-shield]: https://img.shields.io/github/license/zachreborn/terraform-modules.svg?style=for-the-badge
[license-url]: https://github.com/zachreborn/terraform-modules/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/zachary-hill-5524257a/
[product-screenshot]: /images/screenshot.webp
[Terraform.io]: https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform
[Terraform-url]: https://terraform.io
