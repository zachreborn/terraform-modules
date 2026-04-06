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

<h3 align="center">SSM Patch Manager - Baseline</h3>
  <p align="center">
    Creates an AWS Systems Manager Patch Baseline for a specific Linux operating system family, with optional override of the AWS-managed default baseline.
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

### Amazon Linux 2 Baseline

All patches (Security, Bugfix, Enhancement) with a 10-day approval delay.

```hcl
module "baseline_amzn2" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/patch_manager/baseline"

  name             = "org-linux-amzn2"
  operating_system = "AMAZON_LINUX_2"

  approval_rules = [
    {
      approve_after_days  = 10
      approve_until_date  = null
      compliance_level    = "HIGH"
      enable_non_security = true
      patch_filters = [
        { key = "CLASSIFICATION", values = ["Security", "Bugfix", "Enhancement", "Recommended", "Newpackage"] },
        { key = "SEVERITY",       values = ["Critical", "Important", "Medium", "Low"] },
      ]
    }
  ]

  set_as_default_baseline = true

  tags = {
    environment = "prod"
    terraform   = "true"
  }
}
```

### Ubuntu Baseline

Ubuntu uses PRIORITY rather than CLASSIFICATION/SEVERITY.

```hcl
module "baseline_ubuntu" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/patch_manager/baseline"

  name             = "org-linux-ubuntu"
  operating_system = "UBUNTU"

  approval_rules = [
    {
      approve_after_days  = 10
      approve_until_date  = null
      compliance_level    = "UNSPECIFIED"
      enable_non_security = true
      patch_filters = [
        { key = "PRIORITY", values = ["Required", "Important", "Standard", "Optional", "Extra"] },
      ]
    }
  ]

  tags = {
    environment = "prod"
    terraform   = "true"
  }
}
```

### RHEL Baseline

```hcl
module "baseline_rhel" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/patch_manager/baseline"

  name             = "org-linux-rhel"
  operating_system = "REDHAT_ENTERPRISE_LINUX"

  approval_rules = [
    {
      approve_after_days  = 10
      approve_until_date  = null
      compliance_level    = "HIGH"
      enable_non_security = true
      patch_filters = [
        { key = "CLASSIFICATION", values = ["Security", "Bugfix", "Enhancement"] },
        { key = "SEVERITY",       values = ["Critical", "Important", "Moderate", "Low"] },
      ]
    }
  ]

  tags = {
    environment = "prod"
    terraform   = "true"
  }
}
```

> **Note**: Patch filter keys differ by operating system. Refer to the [AWS patch filter documentation](https://docs.aws.amazon.com/systems-manager/latest/userguide/patch-manager-linux-patches.html) for the valid keys per OS family.

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
