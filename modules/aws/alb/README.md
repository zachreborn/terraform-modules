<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->

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
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="300" height="300">
  </a>

<h3 align="center">[Deprecated] - Application Load Balancer Module</h3>
  <p align="center">
    This module has been deprecated in favor of the [modules/aws/lb](/modules/aws/lb/) module. This new module supports both application and network load balancers, and is designed to be more flexible and easier to use.
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

<!-- USAGE EXAMPLES -->

## Migration

The `lb` module can now be utilized to create and maintain either an application load balancer or a network load balancer.

Move the state of any modules utilizing `alb` to the `lb` module using a `moved` block. See the following hashicorp [refactoring](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring) documentation for information on how to perform this.

Match up the resources and components from the `alb` module to the `lb` module

- [alb module](https://github.com/zachreborn/terraform-modules/tree/v5.2.0/modules/aws/alb)
- [lb module](https://github.com/zachreborn/terraform-modules/tree/main/modules/aws/lb)

An example of an application load balancer utilizing the `lb` module can be found [here](https://github.com/zachreborn/terraform-modules/tree/main/modules/aws/lb/README.md).

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version  |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 4.0.0 |

## Providers

| Name                                             | Version  |
| ------------------------------------------------ | -------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name                                                                                                            | Type     |
| --------------------------------------------------------------------------------------------------------------- | -------- |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb)                   | resource |
| [aws_lb_listener.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |

## Inputs

| Name                                                                                                                              | Description                                                                                                                                                                                                                                                                                                                                | Type           | Default         | Required |
| --------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------- | --------------- | :------: |
| <a name="input_access_logs_bucket"></a> [access_logs_bucket](#input_access_logs_bucket)                                           | (Required) The S3 bucket name to store the logs in.                                                                                                                                                                                                                                                                                        | `string`       | n/a             |   yes    |
| <a name="input_access_logs_enabled"></a> [access_logs_enabled](#input_access_logs_enabled)                                        | (Optional) Boolean to enable / disable access_logs. Defaults to false, even when bucket is specified.                                                                                                                                                                                                                                      | `bool`         | `true`          |    no    |
| <a name="input_access_logs_prefix"></a> [access_logs_prefix](#input_access_logs_prefix)                                           | (Optional) The S3 bucket prefix. Logs are stored in the root if not configured.                                                                                                                                                                                                                                                            | `string`       | `"alb-log"`     |    no    |
| <a name="input_drop_invalid_header_fields"></a> [drop_invalid_header_fields](#input_drop_invalid_header_fields)                   | (Optional) Indicates whether HTTP headers with header fields that are not valid are removed by the load balancer (true) or routed to targets (false). The default is false. Elastic Load Balancing requires that message header names contain only alphanumeric characters and hyphens. Only valid for Load Balancers of type application. | `bool`         | `true`          |    no    |
| <a name="input_enable_cross_zone_load_balancing"></a> [enable_cross_zone_load_balancing](#input_enable_cross_zone_load_balancing) | (Optional) If true, cross-zone load balancing of the load balancer will be enabled. This is a network load balancer feature. Defaults to false.                                                                                                                                                                                            | `bool`         | `false`         |    no    |
| <a name="input_enable_deletion_protection"></a> [enable_deletion_protection](#input_enable_deletion_protection)                   | (Optional) If true, deletion of the load balancer will be disabled via the AWS API. This will prevent Terraform from deleting the load balancer. Defaults to false.                                                                                                                                                                        | `bool`         | `false`         |    no    |
| <a name="input_enable_http2"></a> [enable_http2](#input_enable_http2)                                                             | (Optional) Indicates whether HTTP/2 is enabled in application load balancers. Defaults to true.                                                                                                                                                                                                                                            | `bool`         | `true`          |    no    |
| <a name="input_idle_timeout"></a> [idle_timeout](#input_idle_timeout)                                                             | (Optional) The time in seconds that the connection is allowed to be idle. Only valid for Load Balancers of type application. Default: 60.                                                                                                                                                                                                  | `number`       | `60`            |    no    |
| <a name="input_internal"></a> [internal](#input_internal)                                                                         | (Optional) If true, the LB will be internal.                                                                                                                                                                                                                                                                                               | `bool`         | `false`         |    no    |
| <a name="input_ip_address_type"></a> [ip_address_type](#input_ip_address_type)                                                    | (Optional) The type of IP addresses used by the subnets for your load balancer. The possible values are ipv4 and dualstack                                                                                                                                                                                                                 | `string`       | `"ipv4"`        |    no    |
| <a name="input_load_balancer_type"></a> [load_balancer_type](#input_load_balancer_type)                                           | (Optional) The type of load balancer to create. Possible values are application, gateway, or network. The default value is application.                                                                                                                                                                                                    | `string`       | `"application"` |    no    |
| <a name="input_name"></a> [name](#input_name)                                                                                     | (Required) The name of the LB. This name must be unique within your AWS account, can have a maximum of 32 characters, must contain only alphanumeric characters or hyphens, and must not begin or end with a hyphen. If not specified, Terraform will autogenerate a name beginning with tf-lb.                                            | `string`       | n/a             |   yes    |
| <a name="input_number"></a> [number](#input_number)                                                                               | (Optional) the number of resources to create                                                                                                                                                                                                                                                                                               | `number`       | `1`             |    no    |
| <a name="input_security_groups"></a> [security_groups](#input_security_groups)                                                    | (Required) A list of security group IDs to assign to the LB. Only valid for Load Balancers of type application.                                                                                                                                                                                                                            | `list(string)` | n/a             |   yes    |
| <a name="input_subnets"></a> [subnets](#input_subnets)                                                                            | (Optional) A list of subnet IDs to attach to the LB. Subnets cannot be updated for Load Balancers of type network. Changing this value for load balancers of type network will force a recreation of the resource.                                                                                                                         | `list(string)` | n/a             |   yes    |

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
[Next.js]: https://img.shields.io/badge/next.js-000000?style=for-the-badge&logo=nextdotjs&logoColor=white
[Next-url]: https://nextjs.org/
[React.js]: https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB
[React-url]: https://reactjs.org/
[Vue.js]: https://img.shields.io/badge/Vue.js-35495E?style=for-the-badge&logo=vuedotjs&logoColor=4FC08D
[Vue-url]: https://vuejs.org/
[Angular.io]: https://img.shields.io/badge/Angular-DD0031?style=for-the-badge&logo=angular&logoColor=white
[Angular-url]: https://angular.io/
[Svelte.dev]: https://img.shields.io/badge/Svelte-4A4A55?style=for-the-badge&logo=svelte&logoColor=FF3E00
[Svelte-url]: https://svelte.dev/
[Laravel.com]: https://img.shields.io/badge/Laravel-FF2D20?style=for-the-badge&logo=laravel&logoColor=white
[Laravel-url]: https://laravel.com
[Bootstrap.com]: https://img.shields.io/badge/Bootstrap-563D7C?style=for-the-badge&logo=bootstrap&logoColor=white
[Bootstrap-url]: https://getbootstrap.com
[JQuery.com]: https://img.shields.io/badge/jQuery-0769AD?style=for-the-badge&logo=jquery&logoColor=white
[JQuery-url]: https://jquery.com
[Terraform.io]: https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform
[Terraform-url]: https://terraform.io
