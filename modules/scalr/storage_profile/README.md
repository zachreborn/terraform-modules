<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Storage Profile Module</h3>
  <p align="center">
    This module manages Scalr storage profiles (<code>scalr_storage_profile</code>) backed by AWS S3, AzureRM,
    or Google Cloud Storage.
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

## Prerequisites

- The target bucket/container must already exist (AWS S3 bucket, Azure storage container, or Google Storage
  bucket) -- this module does not create the underlying storage itself.
- For AWS S3 and AzureRM backends: an OIDC-federated identity (`audience`, plus `role_arn` for AWS or
  `client_id`/`tenant_id` for Azure) that Scalr can assume.
- For Google backends: a service account JSON key with the `Storage Admin` role on the target bucket.

<!-- USAGE EXAMPLES -->

## Usage

### AWS S3 Example

```hcl
module "storage_profiles" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/storage_profile"

  storage_profiles = {
    primary = {
      default = true
      aws_s3 = {
        audience    = "scalr-storage"
        bucket_name = "my-scalr-state-bucket"
        role_arn    = "arn:aws:iam::123456789012:role/scalr-storage-profile"
        region      = "us-east-1"
      }
    }
  }
}
```

### Google Cloud Storage Example

```hcl
module "storage_profiles" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/storage_profile"

  storage_profiles = {
    gcs_backend = {
      google = {
        storage_bucket = "my-scalr-state-bucket"
        project        = "my-gcp-project"
      }
    }
  }

  google_credentials = {
    gcs_backend = file("${path.module}/secrets/gcs-service-account.json") # or sourced from a secret manager
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- Exactly one of `aws_s3`, `azurerm`, or `google` must be set per entry, enforced by a `validation` block.
- **Why Google `credentials`/`encryption_key` are separate variables:** OpenTofu/Terraform can only mark an
  entire variable as `sensitive`, not a single attribute inside an object-typed variable. Splitting these two
  attributes out into always-sensitive `var.google_credentials` / `var.google_encryption_keys` maps (keyed by
  the same logical name) keeps the rest of each entry's settings visible in plan output while guaranteeing the
  credential/key content is never shown. This mirrors the same design decision made in `modules/scalr/variable`
  and `modules/scalr/ssh_key`. `aws_s3` and `azurerm` have no sensitive sub-attributes per the provider schema
  (they authenticate via OIDC federation, not static secrets), so no equivalent split is needed for them.
- `name` on each entry defaults to its map key when unset, matching the convention used elsewhere in this
  repository.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_scalr"></a> [scalr](#requirement\_scalr) | >= 3.17.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | 3.17.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| scalr_storage_profile.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_google_credentials"></a> [google\_credentials](#input\_google\_credentials) | (Optional) Map of Google Cloud Storage service account JSON key content (the `credentials` attribute of<br/>the storage profile's google block), keyed by the same keys as var.storage\_profiles. Only relevant for<br/>entries that set google. Kept as a separate, always-sensitive variable rather than an attribute nested<br/>inside var.storage\_profiles, since OpenTofu/Terraform cannot mark a single attribute of an object-typed<br/>variable as sensitive -- only whole variables can be marked sensitive. | `map(string)` | `{}` | no |
| <a name="input_google_encryption_keys"></a> [google\_encryption\_keys](#input\_google\_encryption\_keys) | (Optional) Map of Google Cloud Storage customer-supplied encryption keys (the `encryption_key` attribute<br/>of the storage profile's google block; must be exactly 32 bytes, base64-encoded), keyed by the same keys<br/>as var.storage\_profiles. Only relevant for entries that set google. | `map(string)` | `{}` | no |
| <a name="input_storage_profiles"></a> [storage\_profiles](#input\_storage\_profiles) | (Required) Map of Scalr storage profiles (`scalr_storage_profile`) to create, keyed by a caller-chosen<br/>logical name. Exactly one of aws\_s3, azurerm, or google must be set per entry. Sensitive Google<br/>credentials/encryption keys are intentionally excluded from this variable -- see var.google\_credentials<br/>and var.google\_encryption\_keys below.<br/>Fields:<br/>  - name:    (Optional) Name of the storage profile. Defaults to the entry's map key when unset.<br/>  - default: (Optional) Whether this is the default storage profile. Defaults to false.<br/>  - aws\_s3:  (Optional) AWS S3 backend settings. Conflicts with azurerm and google. Object fields:<br/>             - audience:    (Required) The value of the `aud` claim for the identity token.<br/>             - bucket\_name: (Required) AWS S3 bucket name. Bucket must already exist.<br/>             - role\_arn:    (Required) ARN of the IAM role to assume.<br/>             - region:      (Optional) AWS S3 bucket region.<br/>  - azurerm: (Optional) AzureRM backend settings. Conflicts with aws\_s3 and google. Object fields:<br/>             - audience:        (Required) Azure audience for authentication.<br/>             - client\_id:       (Required) Azure client ID for authentication.<br/>             - container\_name:  (Required) Azure storage container name.<br/>             - storage\_account: (Required) Azure storage account name.<br/>             - tenant\_id:       (Required) Azure tenant ID for authentication.<br/>  - google:  (Optional) Google Cloud Storage backend settings. Conflicts with aws\_s3 and azurerm. Object<br/>             fields:<br/>             - storage\_bucket: (Required) Google Storage bucket name. Bucket must already exist.<br/>             - project:        (Optional) Google Cloud project ID.<br/>             (The `credentials` and `encryption_key` attributes are set via var.google\_credentials /<br/>             var.google\_encryption\_keys, keyed by this same entry's map key.) | <pre>map(object({<br/>    name    = optional(string)<br/>    default = optional(bool, false)<br/>    aws_s3 = optional(object({<br/>      audience    = string<br/>      bucket_name = string<br/>      role_arn    = string<br/>      region      = optional(string)<br/>    }))<br/>    azurerm = optional(object({<br/>      audience        = string<br/>      client_id       = string<br/>      container_name  = string<br/>      storage_account = string<br/>      tenant_id       = string<br/>    }))<br/>    google = optional(object({<br/>      storage_bucket = string<br/>      project        = optional(string)<br/>    }))<br/>  }))</pre> | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_created_at"></a> [created\_at](#output\_created\_at) | Map of the resource creation timestamps, keyed by the same keys as var.storage\_profiles. |
| <a name="output_error_messages"></a> [error\_messages](#output\_error\_messages) | Map of the last error description for each storage profile (non-null only when the backend settings don't work properly), keyed by the same keys as var.storage\_profiles. |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr storage profile IDs, keyed by the same keys as var.storage\_profiles. |
| <a name="output_updated_at"></a> [updated\_at](#output\_updated\_at) | Map of the resource last-update timestamps, keyed by the same keys as var.storage\_profiles. |
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

- [Zachary Hill](https://github.com/zachreborn)
- [Jake Jones](https://github.com/jakeasaurus)
- [Brad Engberg](https://github.com/bradms98)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->

[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/zachary-hill-5524257a/
