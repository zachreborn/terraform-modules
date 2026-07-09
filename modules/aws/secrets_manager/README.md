<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

<!-- PROJECT SHIELDS -->
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

<h3 align="center">Secrets Manager</h3>
  <p align="center">
    This module creates one or more AWS Secrets Manager secrets, with optional dedicated KMS encryption keys, automatic rotation, cross-Region replication, and standalone resource policies.
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
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#notes--design-decisions">Notes / Design Decisions</a></li>
    <li><a href="#secret-payload-management">Secret Payload Management</a></li>
    <li><a href="#consuming-secrets-safely">Consuming Secrets Safely</a></li>
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

### Basic secret with a caller-supplied value

```hcl
module "secrets_manager" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/secrets_manager"

  secrets = {
    database_credentials = {
      description = "Application database credentials"
    }
  }

  secret_values = {
    database_credentials = {
      secret_string = jsonencode({
        username = "app_user"
        password = var.database_password
      })
    }
  }

  tags = {
    terraform   = "true"
    environment = "prod"
  }
}
```

### Dedicated KMS key, automatic rotation, and cross-Region replication

```hcl
module "secrets_manager" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/secrets_manager"

  secrets = {
    payments_api_key = {
      description    = "Third-party payments API key"
      create_kms_key = true

      enable_rotation                   = true
      rotation_lambda_arn               = aws_lambda_function.rotate_payments_api_key.arn
      rotation_automatically_after_days = 30

      replica = [
        { region = "us-west-2" }
      ]
    }
  }
}
```

### Zero-state secret value via ephemeral write-only argument

Requires OpenTofu or Terraform >= 1.11 and `hashicorp/random` >= 3.7.0. The generated password
never appears in the plan, state, or Scalr/CI run output -- see
[Secret Payload Management](#secret-payload-management) below for the full decision tree.

```hcl
ephemeral "random_password" "app_token" {
  length  = 32
  special = false
}

module "secrets_manager" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/secrets_manager"

  secrets = {
    internal_service_token = {}
  }

  secret_values = {
    internal_service_token = {
      secret_string_wo         = ephemeral.random_password.app_token.result
      secret_string_wo_version = 1 # bump only when you intend to rotate the value
    }
  }
}
```

### Standalone resource policy with public-access blocking

```hcl
module "secrets_manager" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/secrets_manager"

  secrets = {
    shared_read_only_secret = {
      manage_resource_policy = true
      block_public_policy    = true
      resource_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Sid       = "EnableCrossAccountRead"
          Effect    = "Allow"
          Principal = { AWS = "arn:aws:iam::123456789012:root" }
          Action    = "secretsmanager:GetSecretValue"
          Resource  = "*"
        }]
      })
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- If `enable_rotation = true`, an existing Lambda rotation function and its ARN. This module does not create the rotation function -- rotation function code is specific to the secret's credential type (for example, an AWS-provided rotation template deployed via the `modules/aws/lambda` module or the Serverless Application Repository).
- If `create_kms_key = false` and encryption with a customer managed key is desired, an existing KMS key ARN to pass via `kms_key_id`.
- Before replicating to additional Regions (`replica`), those Regions must already be enabled on the account.

## Notes / Design Decisions

- **One module call, many secrets.** All inputs are keyed maps (`secrets`, `secret_values`) so a single module call can manage any number of secrets, following this repo's scalable-input convention.
- **KMS by composition.** A dedicated customer-managed key is only created when `create_kms_key = true`, via the `../kms` child module -- never inline. The generated key policy is the standard "Enable IAM User Permissions" statement, which delegates all access control to IAM policies in the account; it does not itself restrict usage to Secrets Manager, since KMS key policies are additive-only and a root-principal statement can't be meaningfully narrowed by a second, more specific statement on that same principal. To restrict a specific caller to using the key only through Secrets Manager, add a `kms:ViaService` condition to *that caller's* IAM policy (see [Consuming Secrets Safely](#consuming-secrets-safely)), not to the key policy. When `create_kms_key = false` and `kms_key_id` is unset, Secrets Manager falls back to the AWS managed key `aws/secretsmanager`.
- **Metadata and value are separate inputs.** `secrets` manages secret metadata (name, KMS, rotation, policy, replication) and is not sensitive. `secret_values` manages the actual secret value and is marked `sensitive = true` as a whole, mirroring the provider's own split between `aws_secretsmanager_secret` and `aws_secretsmanager_secret_version`. An entry in `secret_values` with no matching key in `secrets` is ignored rather than erroring, and a `secrets` entry with no matching `secret_values` entry simply has no version created (useful when the value is set out-of-band).
- **`policy` vs. `manage_resource_policy`.** Both ultimately manage the same underlying secret resource policy attribute, so setting both for the same secret is rejected by variable validation. Use `policy` for a simple inline policy, or `manage_resource_policy` + `resource_policy` when you also need `block_public_policy`.
- **Secure defaults.** `recovery_window_in_days` defaults to 30 (not immediate deletion), and `block_public_policy` defaults to `true` whenever a standalone resource policy is managed.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Secret Payload Management

How you populate `secret_values` matters more for your security posture than any setting on this
module. Never commit a real secret value in a `.tf`/`.tfvars`/YAML file, and avoid storing
application secret payloads as plain CI/CD platform variables (for example, Scalr workspace
variables) -- neither approach gives you per-secret audit trails, rotation, or least-privilege
access the way Secrets Manager itself does. Instead, pick the first option below that fits the
secret:

1. **Let AWS own the value entirely (best).** For credentials AWS can manage end-to-end, such as
   an RDS/Aurora master password, use the database resource's own `manage_master_user_password`
   feature instead of `secret_values`. Terraform/OpenTofu and your CI/CD platform never see the
   plaintext.
2. **Ephemeral value + write-only argument (best for values Terraform must generate).** On
   OpenTofu/Terraform >= 1.11 with `hashicorp/random` >= 3.7.0, generate the value with an
   `ephemeral "random_password"` resource and pass it to `secret_values[*].secret_string_wo` /
   `secret_string_wo_version` (see the usage example above). The value is never written to the
   plan or state file. For multi-field secrets (e.g. a username/password pair), combine several
   ephemeral values in a `local` before calling `jsonencode()` on it -- the resulting local is
   automatically treated as ephemeral too, so OpenTofu blocks it from leaking into any
   non-write-only argument or a root output.
3. **Out-of-band population (for human-supplied secrets, e.g. third-party API keys).** Create the
   `secrets` entry with no matching `secret_values` entry -- this produces an empty secret
   container with no sensitive content in the diff or commit history. Populate the value once,
   out-of-band, with `aws secretsmanager put-secret-value`, authorized by a narrowly scoped IAM
   policy (ideally temporary SSO credentials) restricted to that one secret's ARN. This never
   touches Git, Terraform state, or CI/CD platform variables.
4. **`secret_string` (acceptable, not ideal).** A plain `secret_string` is the simplest option but
   is persisted to Terraform/OpenTofu state in plaintext. Only use this for low-sensitivity values,
   and pair it with state encryption (OpenTofu's native `encryption` block, or your remote backend's
   encryption-at-rest) plus tightly scoped read access to that state.

Once a secret's rotation is handled by an AWS-provided Lambda rotation template
(`enable_rotation`), AWS owns the value's lifecycle after the first rotation regardless of which
option above was used to seed it.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Consuming Secrets Safely

Creating the secret is only half of the pattern. The safe consumption model is:

- Terraform/OpenTofu outputs and remote state should pass **secret ARNs/names only**, never secret
  payloads.
- Application runtimes should retrieve the value directly from Secrets Manager at startup or request
  time using their own IAM role.
- IAM permissions should be scoped to the specific secret ARNs the workload needs, plus the matching
  KMS decrypt permission when a customer-managed key is used. This module's composed KMS key policy
  only delegates to IAM (see [Notes / Design Decisions](#notes--design-decisions)) -- if you want to
  restrict a caller to using the key exclusively through Secrets Manager, add a `kms:ViaService`
  condition to *that caller's* IAM policy, as shown in the examples below.
- Prefer a VPC interface endpoint for `com.amazonaws.<region>.secretsmanager` when workloads run in
  private subnets.
- Do **not** use `data "aws_secretsmanager_secret_version"` in Terraform/OpenTofu just to feed
  another resource. That reintroduces the plaintext value into state.

### RDS database credentials

For database master credentials, prefer AWS-managed Secrets Manager integration on the database
resource itself (`manage_master_user_password`) when supported. If you have an application credential
stored by this module, give the application only the secret ARN and permission to read it at runtime.

For AWS-native database access through RDS Proxy, Terraform/OpenTofu can wire the secret ARN without
reading the password:

```hcl
module "secrets_manager" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/secrets_manager"

  secrets = {
    app_db_credentials = {
      description = "Application database user credentials"
    }
  }
}

resource "aws_db_proxy" "app" {
  name                   = "app-db-proxy"
  engine_family          = "POSTGRESQL"
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_security_group_ids = [aws_security_group.rds_proxy.id]
  vpc_subnet_ids         = var.private_subnet_ids

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = module.secrets_manager.arns["app_db_credentials"]
  }
}
```

The RDS Proxy role needs `secretsmanager:GetSecretValue` for the specific secret and, if the secret
uses a customer-managed KMS key, `kms:Decrypt` on that key -- ideally conditioned on `kms:ViaService`
so the role can only use the key through Secrets Manager:

```hcl
data "aws_iam_policy_document" "rds_proxy_secret_access" {
  statement {
    sid       = "ReadDbCredentialsSecret"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [module.secrets_manager.arns["app_db_credentials"]]
  }

  statement {
    sid       = "DecryptViaSecretsManagerOnly"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [module.secrets_manager.kms_key_arns["app_db_credentials"]]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}
```

### Lambda API key or token

For Lambda, store only the secret ARN/name in an environment variable. The function retrieves the
secret at runtime using the Lambda execution role (or the AWS Parameters and Secrets Lambda
Extension if you want local caching and fewer SDK calls):

```hcl
module "secrets_manager" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/secrets_manager"

  secrets = {
    payments_api_key = {
      description = "Payments provider API key"
    }
  }
}

resource "aws_lambda_function" "payments" {
  function_name = "payments-handler"
  role          = aws_iam_role.payments_lambda.arn
  # ...

  environment {
    variables = {
      PAYMENTS_API_KEY_SECRET_ARN = module.secrets_manager.arns["payments_api_key"]
    }
  }
}

resource "aws_iam_role_policy" "payments_lambda_secrets" {
  role = aws_iam_role.payments_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["secretsmanager:GetSecretValue"]
      Resource = module.secrets_manager.arns["payments_api_key"]
    }]
  })
}
```

Application code should read `PAYMENTS_API_KEY_SECRET_ARN`, call Secrets Manager, cache the value in
memory for a short duration, and avoid logging the returned payload. If the secret uses a
customer-managed KMS key, grant `kms:Decrypt` on `module.secrets_manager.kms_key_arns["payments_api_key"]`
conditioned on `kms:ViaService = "secretsmanager.<region>.amazonaws.com"` so the Lambda role can't use
the key for anything other than reading this secret.

### General API key for a non-cloud-native application

For applications that are not Lambda/ECS/EKS-native (for example, software on EC2, a packaged vendor
appliance, or an on-premises service), keep the same shape: configuration contains only the secret
ARN, and the runtime obtains AWS credentials via a short-lived identity mechanism.

Recommended identity options:

- EC2: instance profile role scoped to the exact secret ARN.
- ECS or containerized app: task role scoped to the exact secret ARN.
- On-premises or third-party host: IAM Roles Anywhere or another short-lived credential broker,
  scoped to the exact secret ARN.

Example IAM policy attached to the runtime role:

```hcl
resource "aws_iam_role_policy" "app_read_api_key" {
  role = aws_iam_role.app_runtime.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue"
        ]
        Resource = module.secrets_manager.arns["vendor_api_key"]
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = module.secrets_manager.kms_key_arns["vendor_api_key"]
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${data.aws_region.current.region}.amazonaws.com"
          }
        }
      }
    ]
  })
}
```

The second statement is only needed when the secret uses a customer-managed KMS key
(`create_kms_key = true` or `kms_key_id` set); omit it when relying on the default
`aws/secretsmanager` managed key.

In deployment tooling, pass the ARN as a config value such as `VENDOR_API_KEY_SECRET_ARN`, not the
API key itself. The application entrypoint or startup code retrieves the secret from Secrets Manager
using the runtime role, writes it only to process memory (not a local file), and refreshes it on a
bounded interval if rotation is enabled.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.54.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | ../kms | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_secretsmanager_secret.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_policy) | resource |
| [aws_secretsmanager_secret_rotation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource |
| [aws_secretsmanager_secret_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_secret_values"></a> [secret\_values](#input\_secret\_values) | (Optional) Map of secret values to store, keyed by the same logical name used in var.secrets. Entries<br/>without a corresponding var.secrets key are ignored. Defaults to an empty map (no secret versions<br/>created -- useful when the value will be set out-of-band via the console or CLI). Fields:<br/>  - secret\_string:            (Optional) Text data to store. Exactly one of secret\_string, secret\_string\_wo,<br/>                               or secret\_binary is required per entry.<br/>  - secret\_string\_wo:         (Optional) Write-only text data to store. Requires Terraform/OpenTofu >= 1.11.<br/>  - secret\_string\_wo\_version: (Optional) Increment to trigger an update when secret\_string\_wo changes.<br/>  - secret\_binary:            (Optional) Base64-encoded binary data to store.<br/>  - version\_stages:           (Optional) List of staging labels to attach to this version. | <pre>map(object({<br/>    secret_string            = optional(string)<br/>    secret_string_wo         = optional(string)<br/>    secret_string_wo_version = optional(number)<br/>    secret_binary            = optional(string)<br/>    version_stages           = optional(list(string))<br/>  }))</pre> | `{}` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | (Optional) Map of AWS Secrets Manager secrets to create, keyed by a caller-chosen logical name<br/>(e.g. "database\_credentials"). Defaults to an empty map (no secrets created).<br/>Fields:<br/>  - name:                             (Optional) Friendly name of the secret. Defaults to the entry's<br/>                                       map key when neither name nor name\_prefix is set. Conflicts with<br/>                                       name\_prefix.<br/>  - name\_prefix:                      (Optional) Creates a unique name beginning with the specified<br/>                                       prefix. Conflicts with name.<br/>  - description:                      (Optional) Description of the secret.<br/>  - recovery\_window\_in\_days:          (Optional) Number of days AWS Secrets Manager waits before it can<br/>                                       delete the secret. Must be 0 (force deletion without recovery) or<br/>                                       between 7 and 30 days. Defaults to 30.<br/>  - policy:                           (Optional) Valid JSON document representing a resource policy<br/>                                       managed inline on the secret. Conflicts with manage\_resource\_policy,<br/>                                       since both manage the same underlying resource policy.<br/>  - force\_overwrite\_replica\_secret:   (Optional) Whether to overwrite a secret with the same name in the<br/>                                       destination Region during replication. Defaults to false.<br/>  - replica:                          (Optional) List of Regions to replicate this secret to. Each entry<br/>                                       supports: region (Required), kms\_key\_id (Optional, defaults to the<br/>                                       replica Region's aws/secretsmanager managed key when unset).<br/>  - tags:                             (Optional) Additional tags for this secret, merged with var.tags.<br/>  - create\_kms\_key:                   (Optional) If true, this module creates a dedicated customer managed<br/>                                       KMS key (via modules/aws/kms) to encrypt this secret. Conflicts with<br/>                                       kms\_key\_id. Defaults to false, which lets Secrets Manager use the<br/>                                       AWS managed key (aws/secretsmanager) unless kms\_key\_id is set.<br/>  - kms\_key\_id:                       (Optional) ARN or ID of a caller-supplied KMS key to encrypt the<br/>                                       secret. Conflicts with create\_kms\_key.<br/>  - enable\_rotation:                  (Optional) Whether to manage automatic rotation for this secret.<br/>                                       Defaults to false. When true, rotation\_lambda\_arn is required, along<br/>                                       with exactly one of rotation\_automatically\_after\_days or<br/>                                       rotation\_schedule\_expression.<br/>  - rotation\_lambda\_arn:               (Optional) ARN of the Lambda function that rotates the secret.<br/>                                       Required when enable\_rotation is true. This module does not create<br/>                                       the rotation function itself -- rotation function code is specific<br/>                                       to the secret's credential type, so bring your own function (for<br/>                                       example, one deployed from an AWS-provided rotation template) and<br/>                                       pass its ARN here.<br/>  - rotate\_immediately:               (Optional) Whether to rotate the secret immediately upon enabling<br/>                                       rotation, rather than waiting for the next scheduled window. Defaults<br/>                                       to true.<br/>  - rotation\_automatically\_after\_days: (Optional) Number of days between automatic rotations. Conflicts<br/>                                       with rotation\_schedule\_expression; exactly one is required when<br/>                                       enable\_rotation is true.<br/>  - rotation\_duration:                (Optional) Length of the rotation window, for example "3h".<br/>  - rotation\_schedule\_expression:      (Optional) A cron() or rate() expression defining the rotation<br/>                                       schedule. Conflicts with rotation\_automatically\_after\_days; exactly<br/>                                       one is required when enable\_rotation is true.<br/>  - manage\_resource\_policy:           (Optional) Whether to manage this secret's resource policy via a<br/>                                       standalone aws\_secretsmanager\_secret\_policy resource (needed to set<br/>                                       block\_public\_policy). Defaults to false. Conflicts with policy, since<br/>                                       both manage the same underlying resource policy.<br/>  - resource\_policy:                  (Optional) Valid JSON document representing a resource policy.<br/>                                       Required when manage\_resource\_policy is true.<br/>  - block\_public\_policy:              (Optional) Validates the resource policy to help prevent broad<br/>                                       access to the secret. Only applies when manage\_resource\_policy is<br/>                                       true. Defaults to true. | <pre>map(object({<br/>    name                           = optional(string)<br/>    name_prefix                    = optional(string)<br/>    description                    = optional(string)<br/>    recovery_window_in_days        = optional(number, 30)<br/>    policy                         = optional(string)<br/>    force_overwrite_replica_secret = optional(bool, false)<br/>    replica = optional(list(object({<br/>      region     = string<br/>      kms_key_id = optional(string)<br/>    })), [])<br/>    tags = optional(map(string), {})<br/><br/>    create_kms_key = optional(bool, false)<br/>    kms_key_id     = optional(string)<br/><br/>    enable_rotation                   = optional(bool, false)<br/>    rotation_lambda_arn               = optional(string)<br/>    rotate_immediately                = optional(bool, true)<br/>    rotation_automatically_after_days = optional(number)<br/>    rotation_duration                 = optional(string)<br/>    rotation_schedule_expression      = optional(string)<br/><br/>    manage_resource_policy = optional(bool, false)<br/>    resource_policy        = optional(string)<br/>    block_public_policy    = optional(bool, true)<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Key-value map of resource tags applied to every secret and composed KMS key, merged with each entry's optional per-secret tags. If configured with a provider default\_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level. | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arns"></a> [arns](#output\_arns) | Map of secret ARNs, keyed by the same logical name used in var.secrets. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of secret IDs (ARNs), keyed by the same logical name used in var.secrets. |
| <a name="output_kms_key_arns"></a> [kms\_key\_arns](#output\_kms\_key\_arns) | Map of composed customer managed KMS key ARNs, keyed by the same logical name used in var.secrets. Only includes entries where create\_kms\_key is true. |
| <a name="output_rotation_enabled"></a> [rotation\_enabled](#output\_rotation\_enabled) | Map indicating whether automatic rotation is enabled, keyed by the same logical name used in var.secrets. |
| <a name="output_version_ids"></a> [version\_ids](#output\_version\_ids) | Map of secret version IDs, keyed by the same logical name used in var.secret\_values. |
<!-- END_TF_DOCS -->

<!-- LICENSE -->

## License

Distributed under the MIT License. See `LICENSE` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->

## Contact

Zachary Hill - [![LinkedIn][linkedin-shield]][linkedin-url] - zhill@zacharyhill.co

Project Link: [https://github.com/zachreborn/terraform-modules](https://github.com/zachreborn/terraform-modules)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

- [Zachary Hill](https://github.com/zachreborn)
- [Jake Jones](https://github.com/jakeasaurus)
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
[license-url]: https://github.com/zachreborn/terraform-modules/blob/master/LICENSE
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/zachary-hill-5524257a/
[product-screenshot]: /images/screenshot.webp
[Terraform.io]: https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform
[Terraform-url]: https://terraform.io
