<a name="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Scalr Agent Pool Module</h3>
  <p align="center">
    This module manages Scalr agent pools (<code>scalr_agent_pool</code>) and, optionally, their tokens
    (<code>scalr_agent_pool_token</code>, via the companion <a href="./token">token</a> submodule).
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

- A Scalr account and a configured `scalr` provider.

<!-- USAGE EXAMPLES -->

## Usage

### Simple Example

```hcl
module "agent_pools" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/agent_pool"

  agent_pools = {
    default = {
      environments = ["*"]
      vcs_enabled  = true
    }
  }
}
```

### Composed with a token

```hcl
module "agent_pools" {
  source = "github.com/zachreborn/terraform-modules//modules/scalr/agent_pool"

  agent_pools = {
    default = {
      environments = ["*"]
    }
  }

  agent_pool_tokens = {
    default_token = {
      agent_pool_key = "default" # resolves to module.agent_pools.ids["default"] internally
      description    = "Token for the default pool's agents"
    }
  }
}

# module.agent_pools.tokens["default_token"] is sensitive -- write it to a secret store.
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- `modules/scalr/agent_pool/token` (`scalr_agent_pool_token`) is a standalone, single-resource-focus companion
  submodule that can be used on its own. This module optionally composes it via `agent_pool_tokens`, so a
  single module call can create pools and their tokens together -- mirroring the parent/companion composition
  pattern used by `modules/aws/organizations` and `modules/scalr/var_set`.
- `agent_pool_tokens` entries may reference either a literal `agent_pool_id` or an `agent_pool_key` pointing at
  an entry in `var.agent_pools` created by this same module call; exactly one must be set, enforced by a
  `validation` block.
- `account_id` is still exposed per the provider schema but is deprecated upstream in favor of `environments`;
  prefer `environments` for new pools.
- Header values in `headers` are stored in plan/state like any other list-of-objects attribute -- OpenTofu and
  Terraform cannot mark a single nested attribute as sensitive within an object-typed variable (see
  `modules/scalr/variable`'s design notes for the same limitation). If a header value is itself a secret,
  consider whether it truly needs to flow through this module versus being managed out-of-band.
- `name` on each `agent_pools` entry defaults to its map key when unset, matching the convention used elsewhere
  in this repository.

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
| <a name="provider_scalr"></a> [scalr](#provider\_scalr) | >= 3.17.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_token"></a> [token](#module\_token) | ./token | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| scalr_agent_pool.this | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_agent_pool_header_values"></a> [agent\_pool\_header\_values](#input\_agent\_pool\_header\_values) | Map of sensitive agent pool webhook header values, keyed by the agent pool's logical name<br/>(matching a key in var.agent\_pools) and then by header name. Populate an entry here instead<br/>of setting 'value' directly on a headers entry whenever that header sets 'sensitive = true':<br/>the provider's sensitive flag only controls masking in the Scalr UI and does not prevent the<br/>value from appearing in Terraform/OpenTofu plan output when sourced from a non-sensitive<br/>variable.<br/><br/>Example:<br/>  agent\_pool\_header\_values = {<br/>    default = {<br/>      Authorization = "Bearer my-secret-token"<br/>    }<br/>  } | `map(map(string))` | `{}` | no |
| <a name="input_agent_pool_tokens"></a> [agent\_pool\_tokens](#input\_agent\_pool\_tokens) | (Optional) Map of agent pool tokens to create via the companion ./token submodule, keyed by a<br/>caller-chosen logical name. Each entry must set exactly one of:<br/>  - agent\_pool\_id:  A literal agent pool ID, in the format `apool-<RANDOM STRING>` (e.g. for a pool managed<br/>                    outside this module call).<br/>  - agent\_pool\_key: A key into var.agent\_pools, resolving to the ID of an agent pool created by this same<br/>                    module call. An unknown key fails naturally when OpenTofu/Terraform tries to index<br/>                    scalr\_agent\_pool.this by that key.<br/>Fields:<br/>  - agent\_pool\_id:  (Optional) Literal agent pool ID. Conflicts with agent\_pool\_key.<br/>  - agent\_pool\_key: (Optional) Key into var.agent\_pools. Conflicts with agent\_pool\_id.<br/>  - description:    (Optional) Description of the token. | <pre>map(object({<br/>    agent_pool_id  = optional(string)<br/>    agent_pool_key = optional(string)<br/>    description    = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_agent_pools"></a> [agent\_pools](#input\_agent\_pools) | (Optional) Map of Scalr agent pools (`scalr_agent_pool`) to create, keyed by a caller-chosen logical name<br/>(e.g. "default"). This key can also be referenced by var.agent\_pool\_tokens entries via agent\_pool\_key.<br/>Fields:<br/>  - name:            (Optional) Name of the agent pool. Defaults to the entry's map key when unset.<br/>  - account\_id:      (Optional, Deprecated by the provider in favor of `environments`) ID of the account<br/>                     that owns the pool.<br/>  - environment\_id:  (Optional, Deprecated by the provider in favor of `environments`) ID of a single<br/>                     environment that owns the pool.<br/>  - environments:    (Optional) Set of environment IDs the agent pool is shared to. Use ["*"] to share<br/>                     with all environments.<br/>  - vcs\_enabled:     (Optional) Whether VCS support is enabled for agents in the pool. Defaults to false.<br/>  - api\_gateway\_url: (Optional) HTTP(s) destination URL for the pool's webhook.<br/>  - headers:         (Optional) List of additional headers to set on the pool's webhook request. Each<br/>                     entry sets name (required), value (required, ignored when sensitive = true -- see<br/>                     var.agent\_pool\_header\_values), and sensitive (optional, defaults to false, whether<br/>                     the header value is masked in the Scalr UI). Defaults to an empty list. | <pre>map(object({<br/>    name            = optional(string)<br/>    account_id      = optional(string)<br/>    environment_id  = optional(string)<br/>    environments    = optional(set(string))<br/>    vcs_enabled     = optional(bool, false)<br/>    api_gateway_url = optional(string)<br/>    headers = optional(list(object({<br/>      name      = string<br/>      value     = string<br/>      sensitive = optional(bool, false)<br/>    })), [])<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ids"></a> [ids](#output\_ids) | Map of Scalr agent pool IDs, keyed by the same keys as var.agent\_pools. |
| <a name="output_token_agent_pool_ids"></a> [token\_agent\_pool\_ids](#output\_token\_agent\_pool\_ids) | Map of the agent\_pool\_id actually passed to each scalr\_agent\_pool\_token resource (from the composed ./token submodule), keyed by the same keys as var.agent\_pool\_tokens. Useful for callers/tests that need to prove which agent pool was actually wired into each token. |
| <a name="output_token_ids"></a> [token\_ids](#output\_token\_ids) | Map of agent pool token resource IDs, keyed by the same keys as var.agent\_pool\_tokens. |
| <a name="output_tokens"></a> [tokens](#output\_tokens) | Map of the actual agent pool token secret values, keyed by the same keys as var.agent\_pool\_tokens. Sensitive. |
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
