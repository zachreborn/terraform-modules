<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Docker Integration Module</h3>
  <p align="center">
    This module manages <code>scalr_docker_integration</code> resources in Scalr, storing Docker (OCI) registry credentials that OCI-sourced Scalr modules and runs use to reach a registry.
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

### Prerequisites

- Scalr provider `>= 3.20.0`. The `scalr_docker_integration` resource first shipped in that release.
- A reachable registry and credentials for it: a username plus a password or personal access token. Never commit the credential; pass it in from a secret store or a sensitive variable.
- A Scalr instance that supports Docker (OCI) integrations. The provider's v3.20.0 release notes do not yet state a minimum Scalr server version, so confirm support before applying against a live instance.

### Simple Example

```hcl
variable "ghcr_token" {
  description = "GitHub Container Registry personal access token used by the Scalr integration."
  type        = string
  sensitive   = true
}

module "docker_integration" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/integrations/docker"

  docker_integrations = {
    ghcr = {
      name               = "ghcr"
      registry_url       = "https://ghcr.io"
      username           = "my-user"
      export_credentials = true
    }
  }

  # Keyed by the same logical names as docker_integrations.
  docker_passwords = {
    ghcr = var.ghcr_token
  }
}
```

### Using the Integration With an OCI-Sourced Scalr Module

The `ids` output is the value an OCI-sourced `scalr_module` consumes as its `docker_integration_id`. A resource-level example:

```hcl
resource "scalr_module" "example" {
  # ... OCI source arguments (docker_image, name, module_provider) ...
  docker_integration_id = module.docker_integration.ids["ghcr"]
}
```

If you manage Scalr modules with `modules/scalr/module` in this repository, pass `module.docker_integration.ids["ghcr"]` as the entry's `docker_integration_id` (available once that module supports OCI sources).

### Multiple Registries

```hcl
module "docker_integrations" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/integrations/docker"

  docker_integrations = {
    ghcr = {
      name               = "ghcr"
      registry_url       = "https://ghcr.io"
      username           = "gh-user"
      export_credentials = true
    }
    gitlab = {
      name         = "gitlab"
      registry_url = "https://registry.gitlab.com"
      username     = "my-deploy-token-user"
    }
  }

  docker_passwords = {
    ghcr   = var.ghcr_token
    gitlab = var.gitlab_deploy_token
  }
}
```

### Importing an Existing Integration

Existing integrations can be imported by ID (`in-<RANDOM STRING>`) into the module's resource address:

```shell
tofu import 'module.docker_integration.scalr_docker_integration.this["ghcr"]' in-xxxxxxxxxx
```

The password is never returned by the Scalr API, so the first plan after an import shows the password as a pending in-place change until it is applied.

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_scalr"></a> [scalr](#requirement\_scalr) | >= 3.20.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | >= 3.20.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| scalr_docker_integration.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_docker_integrations"></a> [docker\_integrations](#input\_docker\_integrations) | Map of Scalr Docker (OCI) registry integrations keyed by a caller-chosen logical name. Each<br/>entry manages one `scalr_docker_integration` resource, which stores registry credentials in<br/>Scalr. The integration is what an OCI-sourced `scalr_module` consumes through its<br/>`docker_integration_id`, and it can optionally inject the credentials into runs for direct<br/>`oci://` module access. The sensitive registry password for each entry is intentionally NOT<br/>part of this variable -- see var.docker\_passwords. Keeping it out of this map lets<br/>var.docker\_integrations remain non-sensitive, which is required because it is this module's<br/>for\_each source (OpenTofu/Terraform disallow for\_each over a sensitive collection).<br/><br/>Fields:<br/>  - name:               (Required) Name of the Docker integration. Must not be blank.<br/>  - registry\_url:       (Required) Registry URL, for example "https://ghcr.io". Must start with<br/>                         "https://", include a host, and must not embed credentials. Only one<br/>                         integration per registry host is allowed, so hosts must be unique<br/>                         across entries. Redirecting URLs are rejected by Scalr.<br/>  - username:           (Required) Registry username. Must not be blank.<br/>  - export\_credentials: (Optional) Whether to inject the credentials into plan and apply runs<br/>                         for direct oci:// module access. Defaults to false.<br/><br/>Example:<br/>  docker\_integrations = {<br/>    ghcr = {<br/>      name               = "ghcr"<br/>      registry\_url       = "https://ghcr.io"<br/>      username           = "my-user"<br/>      export\_credentials = true<br/>    }<br/>  } | <pre>map(object({<br/>    name               = string<br/>    registry_url       = string<br/>    username           = string<br/>    export_credentials = optional(bool, false)<br/>  }))</pre> | `{}` | no |
| <a name="input_docker_passwords"></a> [docker\_passwords](#input\_docker\_passwords) | Map of sensitive registry passwords or personal access tokens for var.docker\_integrations,<br/>keyed by the same logical key. Kept in a separate, wholly `sensitive = true` variable so that<br/>var.docker\_integrations itself can remain non-sensitive (required, since it is the for\_each<br/>source for scalr\_docker\_integration.this). Every key in var.docker\_integrations must have a<br/>non-empty entry here, because the underlying provider requires a password for every<br/>integration. Entries without a matching integration are ignored and are not validated.<br/><br/>Example:<br/>  docker\_passwords = {<br/>    ghcr = var.ghcr\_token<br/>  } | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr Docker integration IDs (in-<RANDOM STRING>) keyed by the same logical name used in var.docker\_integrations. Pass an ID to the docker\_integration\_id of an OCI-sourced scalr\_module. |
| <a name="output_statuses"></a> [statuses](#output\_statuses) | Map of Scalr Docker integration statuses, as reported by the latest registry connection test, keyed by the same logical name used in var.docker\_integrations. |
<!-- END_TF_DOCS -->

## Notes / Design Decisions

- **Secrets live in a separate sensitive map.** `docker_integrations` stays non-sensitive so it can drive `for_each` (OpenTofu/Terraform refuse `for_each` over a sensitive collection). Each integration's password is looked up by the same key from the wholly sensitive `docker_passwords` map, the same pattern as `modules/scalr/vcs_provider`.
- **Every integration must have a password.** A cross-variable validation on `docker_passwords` fails the plan, naming the missing keys, when an integration has no entry. Null, empty, and whitespace-only passwords are rejected too, but only for configured integrations: surplus entries in `docker_passwords` are ignored and are not validated. Cross-variable validation needs OpenTofu or Terraform `>= 1.9.0`.
- **No whole-object output.** Unlike some sibling modules, this module does not output the full `scalr_docker_integration` objects because they carry the sensitive `password`. It outputs only the explicit non-sensitive projections `ids` and `statuses`, keyed by the logical name.
- **`registry_url` must be `https://`.** The provider also accepts a bare host and normalizes it, but this module requires an explicit `https://` URL with a host and no embedded credentials (the URL is not sensitive, so a token placed in it would be stored in state and plan output in plain text). Redirecting URLs are rejected by Scalr, so use the registry's canonical host.
- **One integration per registry host.** Scalr allows only one Docker integration per registry host, so the module rejects entries that resolve to the same host. Hosts are compared the way Scalr normalizes them: case-insensitively, ignoring the path, and ignoring the default `:443` port. The same host on a non-default port counts as a different registry.
- **`export_credentials` defaults to `false`.** When `true`, Scalr injects the credentials into plan and apply runs so Terraform can fetch `oci://` modules directly from the registry. That exposes the credentials to every run that can use the integration, so enable it only when runs need direct `oci://` access.
- **Connection test results.** Scalr tests the registry connection when the URL or credentials change. A failed test surfaces as a provider warning and `status` (see the `statuses` output), not as an apply error.

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
