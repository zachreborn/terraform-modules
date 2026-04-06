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

<h3 align="center">SSM Patch Manager - Maintenance Window</h3>
  <p align="center">
    Creates an AWS Systems Manager Maintenance Window with tag-based targets and a RunPatchBaseline task. Includes an IAM service role and optional S3 logging and SNS notifications.
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

## Usage

### Org-Wide Linux Patching (3rd Friday, Midnight Mountain Time)

Patches all registered Linux patch groups on the 3rd Friday of every month, 12am–5am Mountain Time. The schedule automatically adjusts for MST (UTC-7) and MDT (UTC-6) via `America/Denver`.

```hcl
module "linux_patch_window" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/patch_manager/maintenance_window"

  name        = "org-linux-monthly-patch"
  description = "Monthly Linux patching - 3rd Friday 12am-5am MT"

  targets = {
    "linux-amzn2" = {
      description       = "Amazon Linux 2 instances"
      resource_type     = "INSTANCE"
      owner_information = "Platform Engineering"
      tag_key           = "Patch Group"
      tag_values        = ["linux-amzn2"]
    }
    "linux-rhel" = {
      description       = "RHEL instances"
      resource_type     = "INSTANCE"
      owner_information = "Platform Engineering"
      tag_key           = "Patch Group"
      tag_values        = ["linux-rhel"]
    }
    "linux-ubuntu" = {
      description       = "Ubuntu instances"
      resource_type     = "INSTANCE"
      owner_information = "Platform Engineering"
      tag_key           = "Patch Group"
      tag_values        = ["linux-ubuntu"]
    }
  }

  tags = {
    environment = "prod"
    terraform   = "true"
  }
}
```

### With S3 Logging and SNS Notifications

```hcl
module "linux_patch_window" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/patch_manager/maintenance_window"

  name        = "org-linux-monthly-patch"
  description = "Monthly Linux patching - 3rd Friday 12am-5am MT"

  targets = {
    "linux-all" = {
      description       = "All Linux instances"
      resource_type     = "INSTANCE"
      owner_information = "Platform Engineering"
      tag_key           = "Patch Group"
      tag_values        = ["linux-all"]
    }
  }

  enable_s3_logging = true
  create_s3_bucket  = true

  enable_sns_notification = true
  create_sns_topic        = true

  tags = {
    environment = "prod"
    terraform   = "true"
  }
}
```

### With Existing S3 Bucket and SNS Topic

```hcl
module "linux_patch_window" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/patch_manager/maintenance_window"

  name = "org-linux-monthly-patch"

  targets = {
    "linux-prod" = {
      description       = "Production Linux servers"
      resource_type     = "INSTANCE"
      owner_information = "Platform Engineering"
      tag_key           = "Patch Group"
      tag_values        = ["linux-prod"]
    }
  }

  enable_s3_logging = true
  s3_bucket_name    = "my-existing-patch-logs-bucket"

  enable_sns_notification = true
  sns_topic_arn           = "arn:aws:sns:us-east-1:123456789012:my-patch-alerts"

  tags = {
    environment = "prod"
    terraform   = "true"
  }
}
```

> **Prerequisites**:
> - SSM delegated administrator must be registered for `ssm.amazonaws.com` using the `organizations/delegated_admin` module.
> - Managed instances must have the `Patch Group` tag applied and an SSM instance profile attached (managed by the `session_manager` module).
> - Instance profiles must include `s3:PutObject` permission if S3 logging is enabled.

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
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

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
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
