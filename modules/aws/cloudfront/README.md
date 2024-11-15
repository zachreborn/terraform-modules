<!-- Blank module readme template: Do a search and replace with your text editor for the following: `module_name`, `module_description` -->
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
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="300" height="300">
  </a>

<h3 align="center">Cloudfront</h3>
  <p align="center">
    This module creates an AWS Cloudfront distribution.
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
## Usage
### Simple Example
```
module test {
  source = 

  variable = 
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_cache_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | (Optional) The ARN of the ACM certificate that you want to use with the distribution. This must be used if custom domain names are used. The ACM certificate must be in the us-east-1 (Virginia) region. | `string` | `null` | no |
| <a name="input_aliases"></a> [aliases](#input\_aliases) | (Optional) Extra CNAMEs (alternate domain names), if any, for this distribution. | `list(string)` | `null` | no |
| <a name="input_cloudfront_default_certificate"></a> [cloudfront\_default\_certificate](#input\_cloudfront\_default\_certificate) | (Optional) Whether to use the cloudfront default SSL certificate with the distribution. Requires using the default Cloudfont domain name as the distribution domain name. Defaults to false. | `bool` | `false` | no |
| <a name="input_comment"></a> [comment](#input\_comment) | (Optional) Any comments you want to include about the distribution. | `string` | `null` | no |
| <a name="input_continuous_deployment_policy_id"></a> [continuous\_deployment\_policy\_id](#input\_continuous\_deployment\_policy\_id) | (Optional) The ID of the ECR image scanning configuration to use. If omitted, no configuration will be used. | `string` | `null` | no |
| <a name="input_custom_error_response"></a> [custom\_error\_response](#input\_custom\_error\_response) | (Optional) One or more custom error response elements (multiples allowed). | <pre>list(object({<br/>    error_caching_min_ttl = optional(number) # The minimum amount of time you want HTTP error codes to stay in CloudFront caches before CloudFront queries your origin to see whether the object has been updated.<br/>    error_code            = number           # 4xx or 5xx HTTP status code that you want customized.<br/>    response_code         = optional(number) # HTTP status code to return.<br/>    response_page_path    = optional(string) # Path of the custom error page (for example, /custom_404.html). Must begin with a slash (/).<br/>  }))</pre> | `null` | no |
| <a name="input_default_cache_allowed_methods"></a> [default\_cache\_allowed\_methods](#input\_default\_cache\_allowed\_methods) | (Optional) Controls which HTTP methods CloudFront processes and forwards to your Amazon S3 bucket or your custom origin. | `list(string)` | <pre>[<br/>  "GET",<br/>  "HEAD"<br/>]</pre> | no |
| <a name="input_default_cache_cached_methods"></a> [default\_cache\_cached\_methods](#input\_default\_cache\_cached\_methods) | (Optional) Controls whether CloudFront caches the response to requests using the specified HTTP methods. | `list(string)` | <pre>[<br/>  "GET",<br/>  "HEAD"<br/>]</pre> | no |
| <a name="input_default_cache_compress"></a> [default\_cache\_compress](#input\_default\_cache\_compress) | (Optional) Whether you want CloudFront to automatically compress content for web requests that include Accept-Encoding: gzip in the request header. | `bool` | `true` | no |
| <a name="input_default_cache_field_level_encryption_id"></a> [default\_cache\_field\_level\_encryption\_id](#input\_default\_cache\_field\_level\_encryption\_id) | (Optional) The field level encryption id to attach to the default cache behavior. | `string` | `null` | no |
| <a name="input_default_cache_origin_request_policy_id"></a> [default\_cache\_origin\_request\_policy\_id](#input\_default\_cache\_origin\_request\_policy\_id) | (Optional) The origin request policy id to attach to the default cache behavior. | `string` | `null` | no |
| <a name="input_default_cache_policy_id"></a> [default\_cache\_policy\_id](#input\_default\_cache\_policy\_id) | (Optional) The cache policy id to attach to the default cache behavior. This is required if `managed_cache_policy_name` is not set. | `string` | `null` | no |
| <a name="input_default_cache_realtime_log_config_arn"></a> [default\_cache\_realtime\_log\_config\_arn](#input\_default\_cache\_realtime\_log\_config\_arn) | (Optional) The ARN of the real-time log configuration to use for the default cache behavior. | `string` | `null` | no |
| <a name="input_default_cache_response_headers_policy_id"></a> [default\_cache\_response\_headers\_policy\_id](#input\_default\_cache\_response\_headers\_policy\_id) | (Optional) The response headers policy id to attach to the default cache behavior. | `string` | `null` | no |
| <a name="input_default_cache_smooth_streaming"></a> [default\_cache\_smooth\_streaming](#input\_default\_cache\_smooth\_streaming) | (Optional) Indicates whether you want to distribute media files in Microsoft Smooth Streaming format using the origin that is associated with this cache behavior. | `bool` | `false` | no |
| <a name="input_default_cache_target_origin_id"></a> [default\_cache\_target\_origin\_id](#input\_default\_cache\_target\_origin\_id) | (Required) The unique identifier of the origin request policy to attach to the default cache behavior. | `string` | n/a | yes |
| <a name="input_default_cache_trusted_key_groups"></a> [default\_cache\_trusted\_key\_groups](#input\_default\_cache\_trusted\_key\_groups) | (Optional) The key groups that CloudFront can use to validate signed URLs or signed cookies. | `list(string)` | `null` | no |
| <a name="input_default_cache_trusted_signers"></a> [default\_cache\_trusted\_signers](#input\_default\_cache\_trusted\_signers) | (Optional) The AWS accounts, if any, that you want to allow to create signed URLs for private content. | `list(string)` | `null` | no |
| <a name="input_default_cache_viewer_protocol_policy"></a> [default\_cache\_viewer\_protocol\_policy](#input\_default\_cache\_viewer\_protocol\_policy) | (Optional) The protocol that viewers can use to access the files in the origin specified by TargetOriginId when a request matches the path pattern in PathPattern. | `string` | `"allow-all"` | no |
| <a name="input_default_root_object"></a> [default\_root\_object](#input\_default\_root\_object) | (Optional) The object that you want CloudFront to return (for example, index.html) when an end user requests the root URL. | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | (Optional) Whether the distribution is enabled to accept end user requests for content. | `bool` | `true` | no |
| <a name="input_geo_restriction_locations"></a> [geo\_restriction\_locations](#input\_geo\_restriction\_locations) | (Optional) The list of country codes for which you want CloudFront either to distribute your content (whitelist) or not distribute your content (blacklist). | `list(string)` | `null` | no |
| <a name="input_geo_restriction_type"></a> [geo\_restriction\_type](#input\_geo\_restriction\_type) | (Optional) The method that you want to use to restrict distribution of your content by country: none, whitelist, or blacklist. | `string` | `"blacklist"` | no |
| <a name="input_http_version"></a> [http\_version](#input\_http\_version) | (Optional) The maximum HTTP version to support on the distribution. Allowed values are http1.1, http2, http2and3, and http3. | `string` | `"http2"` | no |
| <a name="input_iam_certificate_id"></a> [iam\_certificate\_id](#input\_iam\_certificate\_id) | (Optional) The IAM certificate id of the custom viewer certificate for this distribution if you are using a custom domain. | `string` | `null` | no |
| <a name="input_is_ipv6_enabled"></a> [is\_ipv6\_enabled](#input\_is\_ipv6\_enabled) | (Optional) Whether the IPv6 is enabled for the distribution. | `bool` | `true` | no |
| <a name="input_logging_config"></a> [logging\_config](#input\_logging\_config) | (Optional) The logging configuration that controls how logs are written to your distribution (multiples allowed). | <pre>object({<br/>    bucket          = string                # S3 bucket where the logs will be stored.<br/>    include_cookies = optional(bool, false) # Whether the cookies are logged in the access logs. Defaults to false.<br/>    prefix          = optional(string)      # The prefix for the log files.<br/>  })</pre> | `null` | no |
| <a name="input_managed_cache_policy_name"></a> [managed\_cache\_policy\_name](#input\_managed\_cache\_policy\_name) | (Optional) The name of the managed cache policy to use for the default cache behavior. Example: `CachingOptimized`. | `string` | `null` | no |
| <a name="input_ordered_cache_behavior"></a> [ordered\_cache\_behavior](#input\_ordered\_cache\_behavior) | (Optional) One or more ordered cache behavior elements (multiples allowed). The values are the same from the default\_cache\_behaviors with the exception of requiring path\_pattern. | <pre>map(object({<br/>    allowed_methods            = list(string)           # Controls which HTTP methods CloudFront processes and forwards to your Amazon S3 bucket or your custom origin.<br/>    cached_methods             = list(string)           # Controls whether CloudFront caches the response to requests using the specified HTTP methods.<br/>    cache_policy_id            = string                 # The cache policy id to attach to the cache behavior.<br/>    compress                   = optional(bool)         # Whether you want CloudFront to automatically compress content for web requests that include Accept-Encoding: gzip in the request header.<br/>    field_level_encryption_id  = optional(string)       # The field level encryption id to attach to the cache behavior.<br/>    origin_request_policy_id   = string                 # The origin request policy id to attach to the cache behavior.<br/>    path_pattern               = string                 # The pattern (for example, images/*.jpg) that specifies which requests to apply the behavior to.<br/>    realtime_log_config_arn    = optional(string)       # The ARN of the real-time log configuration to use for the cache behavior.<br/>    response_headers_policy_id = optional(string)       # The response headers policy id to attach to the cache behavior.<br/>    smooth_streaming           = optional(bool)         # Indicates whether you want to distribute media files in Microsoft Smooth Streaming format using the origin that is associated with this cache behavior.<br/>    target_origin_id           = string                 # The unique identifier of the origin request policy to attach to the cache behavior.<br/>    trusted_key_groups         = optional(list(string)) # The key groups that CloudFront can use to validate signed URLs or signed cookies.<br/>    trusted_signers            = optional(list(string)) # The AWS accounts, if any, that you want to allow to create signed URLs for private content.<br/>    viewer_protocol_policy     = optional(string)       # The protocol that viewers can use to access the files in the origin specified by TargetOriginId when a request matches the path pattern in PathPattern.<br/>  }))</pre> | `null` | no |
| <a name="input_origin"></a> [origin](#input\_origin) | (Required) One or more origins for this distribution (multiples allowed). The keys should be the origin ID you'd like to use for the origin. | <pre>map(object({<br/>    connection_attempts      = optional(number, 3)  # The number of times that CloudFront attempts to connect to the origin; valid values are 1, 2, or 3 attempts. Defaults to 3.<br/>    connection_timeout       = optional(number, 10) # The number of seconds that CloudFront waits when trying to establish a connection to the origin. Must be between 1-10. Defaults to 10.<br/>    domain_name              = string               # The DNS domain name of the S3 bucket or the HTTP server where the content is located.<br/>    origin_access_control_id = optional(string)     # The origin access identity to associate with the origin.<br/>    origin_path              = optional(string)     # An optional element that causes CloudFront to request your content from a directory in your Amazon S3 bucket or your custom origin.<br/>    custom_header = optional(object({<br/>      header_name  = string # The name of the header.<br/>      header_value = string # The value of the header.<br/>    }))                     # One or more custom headers that you want to include in the origin request.<br/>    custom_origin_config = optional(object({<br/>      http_port                 = optional(number, 80)   # The HTTP port the custom origin listens on.<br/>      https_port                = optional(number, 443)  # The HTTPS port the custom origin listens on.<br/>      origins_keepalive_timeout = optional(number, 5)    # The keepalive timeout for the origin.<br/>      origin_protocol_policy    = optional(string)       # The origin protocol policy to apply to your origin. Must be one of http-only, https-only, or match-viewer.<br/>      origin_read_timeout       = optional(number, 30)   # The read timeout for the origin.<br/>      origin_ssl_protocols      = optional(list(string)) # The SSL/TLS protocols that you want CloudFront to use when communicating with your origin over HTTPS.<br/>    }))                                                  # The custom origin configuration information.<br/>    origin_shield = optional(object({<br/>      enabled              = bool             # Whether Origin Shield is enabled.<br/>      origin_shield_region = optional(string) # The region for Origin Shield.<br/>    }))                                       # The region for Origin Shield.<br/>    s3_origin_config = optional(object({<br/>      origin_access_identity = optional(string) # The CloudFront origin access identity to associate with the origin.<br/>    }))                                         # The S3 origin configuration information.<br/>  }))</pre> | n/a | yes |
| <a name="input_price_class"></a> [price\_class](#input\_price\_class) | (Optional) The price class for this distribution. One of PriceClass\_All, PriceClass\_200, PriceClass\_100. See the AWS documentation for more details at https://docs.aws.amazon.com/cdk/api/v2/python/aws_cdk.aws_cloudfront/PriceClass.html. | `string` | `"PriceClass_100"` | no |
| <a name="input_retain_on_delete"></a> [retain\_on\_delete](#input\_retain\_on\_delete) | (Optional) Disables the distribution instead of deleting it when destroying the resource through Terraform. If this is set, the distribution needs to be deleted manually afterwards. Default is false. | `bool` | `false` | no |
| <a name="input_ssl_minimum_protocol_version"></a> [ssl\_minimum\_protocol\_version](#input\_ssl\_minimum\_protocol\_version) | (Optional) The minimum version of the SSL protocol that you want CloudFront to use for HTTPS connections. Can only be set if the ssl\_support\_method is set to sni-only or vip. | `string` | `"TLSv1.2_2021"` | no |
| <a name="input_ssl_support_method"></a> [ssl\_support\_method](#input\_ssl\_support\_method) | (Optional) Specifies how you want CloudFront to serve HTTPS requests. One of vip, sni-only, or static-ip. | `string` | `"sni-only"` | no |
| <a name="input_staging"></a> [staging](#input\_staging) | (Optional) Whether the distribution is in a staging environment. Default is false. | `bool` | `false` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags to assign to the device. | `map(any)` | <pre>{<br/>  "created_by": "terraform",<br/>  "environment": "prod",<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_wait_for_deployment"></a> [wait\_for\_deployment](#input\_wait\_for\_deployment) | (Optional) If enabled, the resource will wait for the distribution status to change from InProgress to Deployed. Setting this to false will skip the process. Default is true. | `bool` | `true` | no |
| <a name="input_web_acl_id"></a> [web\_acl\_id](#input\_web\_acl\_id) | (Optional) The AWS WAF WebACL to associate with this distribution. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the CloudFront distribution |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | Domain name corresponding to the distribution |
| <a name="output_hosted_zone_id"></a> [hosted\_zone\_id](#output\_hosted\_zone\_id) | The Route 53 Hosted Zone ID that can be used to route an Alias record to |
| <a name="output_id"></a> [id](#output\_id) | ID of the CloudFront distribution |
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

* [Zachary Hill](https://zacharyhill.co)
* [Jake Jones](https://github.com/jakeasarus)

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