<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Workload Identity Provider Module</h3>
  <p align="center">
    This module manages <code>scalr_workload_identity_provider</code> resources in Scalr, allowing an external OIDC identity provider (e.g. GitHub Actions, GitLab CI) to authenticate without a long-lived credential.
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
    <li><a href="#notes--design-decisions">Notes / Design Decisions</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

<!-- USAGE EXAMPLES -->
## Usage

### Simple Example

```hcl
module "workload_identity_provider" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/workload_identity_provider"

  workload_identity_providers = {
    github_actions = {
      name              = "github-actions"
      url               = "https://token.actions.githubusercontent.com"
      allowed_audiences = ["scalr-github-actions"]
    }
    gitlab_ci = {
      name              = "gitlab-ci"
      url               = "https://gitlab.com"
      allowed_audiences = ["scalr-gitlab-ci"]
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_scalr"></a> [scalr](#requirement\_scalr) | >= 3.17.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | >= 3.17.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| scalr_workload_identity_provider.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_workload_identity_providers"></a> [workload\_identity\_providers](#input\_workload\_identity\_providers) | Map of Scalr workload identity providers keyed by a caller-supplied logical name. Each<br/>entry manages one `scalr_workload_identity_provider` resource, allowing an external OIDC<br/>identity provider (e.g. GitHub Actions, GitLab CI) to assume a Scalr service account<br/>without a long-lived credential.<br/><br/>Fields:<br/>  - name:              (Required) Name of the workload identity provider.<br/>  - url:                (Required) The URL of the workload identity provider.<br/>  - allowed\_audiences:  (Required) Set of allowed audiences. Must contain between 1 and 10<br/>                        elements.<br/><br/>Example:<br/>  workload\_identity\_providers = {<br/>    github\_actions = {<br/>      name              = "github-actions"<br/>      url               = "https://token.actions.githubusercontent.com"<br/>      allowed\_audiences = ["scalr-github-actions"]<br/>    }<br/>  } | <pre>map(object({<br/>    name              = string<br/>    url               = string<br/>    allowed_audiences = set(string)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr workload identity provider IDs keyed by the same logical name used in var.workload\_identity\_providers. |
| <a name="output_workload_identity_providers"></a> [workload\_identity\_providers](#output\_workload\_identity\_providers) | Map of full scalr\_workload\_identity\_provider resource objects keyed by the same logical name used in var.workload\_identity\_providers. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **`allowed_audiences` size guard.** A validation rule enforces the provider's documented 1–10 element constraint on `allowed_audiences` at plan time, rather than surfacing a less clear error from the API at apply time.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

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
