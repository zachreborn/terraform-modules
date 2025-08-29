###########################
# Resource Variables
###########################

variable "acm_certificate_arn" {
  description = "(Optional) The ARN of the ACM certificate that you want to use with the distribution. This must be used if custom domain names are used. The ACM certificate must be in the us-east-1 (Virginia) region."
  type        = string
  default     = null
}

variable "aliases" {
  description = "(Optional) Extra CNAMEs (alternate domain names), if any, for this distribution."
  type        = list(string)
  default     = null
}

variable "cloudfront_default_certificate" {
  description = "(Optional) Whether to use the cloudfront default SSL certificate with the distribution. Requires using the default Cloudfont domain name as the distribution domain name. Defaults to false."
  type        = bool
  default     = false
}

variable "comment" {
  description = "(Optional) Any comments you want to include about the distribution."
  type        = string
  default     = null
}

variable "continuous_deployment_policy_id" {
  description = "(Optional) The ID of the ECR image scanning configuration to use. If omitted, no configuration will be used."
  type        = string
  default     = null
}

variable "custom_error_responses" {
  description = "(Optional) One or more custom error response elements (multiples allowed)."
  type = map(object({
    error_caching_min_ttl = optional(number) # The minimum amount of time you want HTTP error codes to stay in CloudFront caches before CloudFront queries your origin to see whether the object has been updated.
    error_code            = number           # 4xx or 5xx HTTP status code that you want customized.
    response_code         = optional(number) # HTTP status code to return.
    response_page_path    = optional(string) # Path of the custom error page (for example, /custom_404.html). Must begin with a slash (/).
  }))
  default = null
}

variable "default_cache_allowed_methods" {
  description = "(Optional) Controls which HTTP methods CloudFront processes and forwards to your Amazon S3 bucket or your custom origin."
  type        = list(string)
  default     = ["GET", "HEAD"]
  validation {
    condition = alltrue([
      for item in var.default_cache_allowed_methods : anytrue([
        item == "GET",
        item == "HEAD",
        item == "OPTIONS",
        item == "PUT",
        item == "PATCH",
        item == "POST",
        item == "DELETE"
      ])
    ])
    error_message = "Invalid value for default_cache_allowed_methods. Must be one or more of GET, HEAD, OPTIONS, PUT, PATCH, POST, or DELETE."
  }
}

variable "default_cache_cached_methods" {
  description = "(Optional) Controls whether CloudFront caches the response to requests using the specified HTTP methods."
  type        = list(string)
  default     = ["GET", "HEAD"]
  validation {
    condition = alltrue([
      for item in var.default_cache_cached_methods : anytrue([
        item == "GET",
        item == "HEAD",
        item == "OPTIONS"
      ])
    ])
    error_message = "Invalid value for default_cache_cached_methods. Must be one or more of GET, HEAD, or OPTIONS."
  }
}

variable "default_cache_policy_id" {
  description = "(Optional) The cache policy id to attach to the default cache behavior. This is required if `managed_cache_policy_name` is not set."
  type        = string
  default     = null
}

variable "default_cache_compress" {
  description = "(Optional) Whether you want CloudFront to automatically compress content for web requests that include Accept-Encoding: gzip in the request header."
  type        = bool
  default     = true
}

variable "default_cache_field_level_encryption_id" {
  description = "(Optional) The field level encryption id to attach to the default cache behavior."
  type        = string
  default     = null
}

variable "default_cache_lambda_function_associations" {
  description = "(Optional) A set of Lambda function associations for the default cache behavior."
  type = map(object({
    event_type   = string # The specific event to trigger this function. Valid values are viewer-request, origin-request, viewer-response, and origin-response.
    lambda_arn   = string # The ARN of the Lambda function.
    include_body = optional(bool, false) # Whether the body of the request/response is available to the Lambda function.
  }))
  default = null
}

variable "default_cache_origin_request_policy_id" {
  description = "(Optional) The origin request policy id to attach to the default cache behavior."
  type        = string
  default     = null
}

variable "default_cache_realtime_log_config_arn" {
  description = "(Optional) The ARN of the real-time log configuration to use for the default cache behavior."
  type        = string
  default     = null
}

variable "default_cache_response_headers_policy_id" {
  description = "(Optional) The response headers policy id to attach to the default cache behavior."
  type        = string
  default     = null
}

variable "default_cache_smooth_streaming" {
  description = "(Optional) Indicates whether you want to distribute media files in Microsoft Smooth Streaming format using the origin that is associated with this cache behavior."
  type        = bool
  default     = false
}

variable "default_cache_target_origin_id" {
  description = "(Required) The unique identifier of the origin request policy to attach to the default cache behavior."
  type        = string
}

variable "default_cache_trusted_key_groups" {
  description = "(Optional) The key groups that CloudFront can use to validate signed URLs or signed cookies."
  type        = list(string)
  default     = null
}

variable "default_cache_trusted_signers" {
  description = "(Optional) The AWS accounts, if any, that you want to allow to create signed URLs for private content."
  type        = list(string)
  default     = null
}

variable "default_cache_viewer_protocol_policy" {
  description = "(Optional) The protocol that viewers can use to access the files in the origin specified by TargetOriginId when a request matches the path pattern in PathPattern."
  type        = string
  default     = "allow-all"
  validation {
    condition     = can(regex("^(allow-all|https-only|redirect-to-https)$", var.default_cache_viewer_protocol_policy))
    error_message = "Invalid value for default_cache_viewer_protocol_policy. Must be one of allow-all, https-only, or redirect-to-https."
  }
}

variable "default_root_object" {
  description = "(Optional) The object that you want CloudFront to return (for example, index.html) when an end user requests the root URL."
  type        = string
  default     = null
}

variable "enabled" {
  description = "(Optional) Whether the distribution is enabled to accept end user requests for content."
  type        = bool
  default     = true
}

variable "geo_restriction_locations" {
  description = "(Optional) The list of country codes for which you want CloudFront either to distribute your content (whitelist) or not distribute your content (blacklist)."
  type        = list(string)
  default     = null
}

variable "geo_restriction_type" {
  description = "(Optional) The method that you want to use to restrict distribution of your content by country: none, whitelist, or blacklist."
  type        = string
  default     = "none"
  validation {
    condition     = can(regex("^(none|whitelist|blacklist)$", var.geo_restriction_type))
    error_message = "Invalid value for geo_restriction_type. Must be one of none, whitelist, or blacklist."
  }
}

variable "http_version" {
  description = "(Optional) The maximum HTTP version to support on the distribution. Allowed values are http1.1, http2, http2and3, and http3."
  type        = string
  default     = "http2"
  validation {
    condition     = can(regex("^(http1.1|http2|http2and3|http3)$", var.http_version))
    error_message = "Invalid value for http_version. Must be one of http1.1, http2, http2and3, or http3."
  }
}

variable "iam_certificate_id" {
  description = "(Optional) The IAM certificate id of the custom viewer certificate for this distribution if you are using a custom domain."
  type        = string
  default     = null
}

variable "is_ipv6_enabled" {
  description = "(Optional) Whether the IPv6 is enabled for the distribution."
  type        = bool
  default     = true
}

variable "logging_config" {
  description = "(Optional) The logging configuration that controls how logs are written to your distribution (multiples allowed)."
  type = object({
    bucket          = string                # S3 bucket where the logs will be stored.
    include_cookies = optional(bool, false) # Whether the cookies are logged in the access logs. Defaults to false.
    prefix          = optional(string)      # The prefix for the log files.
  })
  default = null
}

variable "managed_cache_policy_name" {
  description = "(Optional) The name of the managed cache policy to use for the default cache behavior. Example: `CachingOptimized`."
  type        = string
  default     = null
}

variable "ordered_cache_behavior" {
  description = "(Optional) One or more ordered cache behavior elements (multiples allowed). The values are the same from the default_cache_behaviors with the exception of requiring path_pattern."
  type = map(object({
    allowed_methods            = list(string)           # Controls which HTTP methods CloudFront processes and forwards to your Amazon S3 bucket or your custom origin.
    cached_methods             = list(string)           # Controls whether CloudFront caches the response to requests using the specified HTTP methods.
    cache_policy_id            = string                 # The cache policy id to attach to the cache behavior.
    compress                   = optional(bool)         # Whether you want CloudFront to automatically compress content for web requests that include Accept-Encoding: gzip in the request header.
    field_level_encryption_id  = optional(string)       # The field level encryption id to attach to the cache behavior.
    lambda_function_associations = optional(map(object({
      event_type   = string                              # The specific event to trigger this function. Valid values are viewer-request, origin-request, viewer-response, and origin-response.
      lambda_arn   = string                              # The ARN of the Lambda function.
      include_body = optional(bool, false)               # Whether the body of the request/response is available to the Lambda function.
    })))                                                 # A set of Lambda function associations for the cache behavior.
    origin_request_policy_id   = string                 # The origin request policy id to attach to the cache behavior.
    path_pattern               = string                 # The pattern (for example, images/*.jpg) that specifies which requests to apply the behavior to.
    realtime_log_config_arn    = optional(string)       # The ARN of the real-time log configuration to use for the cache behavior.
    response_headers_policy_id = optional(string)       # The response headers policy id to attach to the cache behavior.
    smooth_streaming           = optional(bool)         # Indicates whether you want to distribute media files in Microsoft Smooth Streaming format using the origin that is associated with this cache behavior.
    target_origin_id           = string                 # The unique identifier of the origin request policy to attach to the cache behavior.
    trusted_key_groups         = optional(list(string)) # The key groups that CloudFront can use to validate signed URLs or signed cookies.
    trusted_signers            = optional(list(string)) # The AWS accounts, if any, that you want to allow to create signed URLs for private content.
    viewer_protocol_policy     = optional(string)       # The protocol that viewers can use to access the files in the origin specified by TargetOriginId when a request matches the path pattern in PathPattern.
  }))
  default = null
}

variable "origins" {
  description = "(Required) One or more origins for this distribution (multiples allowed). The keys should be the origin ID you'd like to use for the origin."
  type = map(object({
    connection_attempts      = optional(number, 3)  # The number of times that CloudFront attempts to connect to the origin; valid values are 1, 2, or 3 attempts. Defaults to 3.
    connection_timeout       = optional(number, 10) # The number of seconds that CloudFront waits when trying to establish a connection to the origin. Must be between 1-10. Defaults to 10.
    domain_name              = string               # The DNS domain name of the S3 bucket or the HTTP server where the content is located.
    origin_access_control_id = optional(string)     # The origin access identity to associate with the origin.
    origin_path              = optional(string)     # An optional element that causes CloudFront to request your content from a directory in your Amazon S3 bucket or your custom origin.
    custom_headers = optional(list(object({
      header_name  = string # The name of the header.
      header_value = string # The value of the header.
    })))                    # One or more custom headers that you want to include in the origin request.
    custom_origin_config = optional(object({
      http_port                = optional(number, 80)                                    # The HTTP port the custom origin listens on.
      https_port               = optional(number, 443)                                   # The HTTPS port the custom origin listens on.
      origin_keepalive_timeout = optional(number, 5)                                     # The keepalive timeout for the origin.
      origin_protocol_policy   = optional(string, "http-only")                           # The origin protocol policy to apply to your origin. Must be one of http-only, https-only, or match-viewer.
      origin_read_timeout      = optional(number, 30)                                    # The read timeout for the origin.
      origin_ssl_protocols     = optional(list(string), ["TLSv1", "TLSv1.1", "TLSv1.2"]) # The SSL/TLS protocols that you want CloudFront to use when communicating with your origin over HTTPS.
    }))                                                                                  # The custom origin configuration information.
    origin_shield = optional(object({
      enabled              = bool             # Whether Origin Shield is enabled.
      origin_shield_region = optional(string) # The region for Origin Shield.
    }))                                       # The region for Origin Shield.
    s3_origin_config = optional(object({
      origin_access_identity = string # The CloudFront origin access identity to associate with the origin.
    }))                               # The S3 origin configuration information.
  }))
}

variable "price_class" {
  description = "(Optional) The price class for this distribution. One of PriceClass_All, PriceClass_200, PriceClass_100. See the AWS documentation for more details at https://docs.aws.amazon.com/cdk/api/v2/python/aws_cdk.aws_cloudfront/PriceClass.html."
  type        = string
  default     = "PriceClass_All"
  validation {
    condition     = can(regex("^(PriceClass_All|PriceClass_200|PriceClass_100)$", var.price_class))
    error_message = "Invalid value for price_class. Must be one of PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "retain_on_delete" {
  description = "(Optional) Disables the distribution instead of deleting it when destroying the resource through Terraform. If this is set, the distribution needs to be deleted manually afterwards. Default is false."
  type        = bool
  default     = false
}

variable "ssl_minimum_protocol_version" {
  description = "(Optional) The minimum version of the SSL protocol that you want CloudFront to use for HTTPS connections. Can only be set if the ssl_support_method is set to sni-only or vip."
  type        = string
  default     = "TLSv1.2_2021"
  validation {
    condition     = can(regex("^(TLSv1|TLSv1_2016|TLSv1.1_2016|TLSv1.2_2018|TLSv1.2_2019|TLSv1.2_2021)$", var.ssl_minimum_protocol_version))
    error_message = "Invalid value for ssl_minimum_protocol_version. Must be one of TLSv1, TLSv1_2016, TLSv1.1_2016, TLSv1.2_2018, TLSv1.2_2019, or TLSv1.2_2021."
  }
}

variable "ssl_support_method" {
  description = "(Optional) Specifies how you want CloudFront to serve HTTPS requests. One of vip, sni-only, or static-ip."
  type        = string
  default     = "sni-only"
  validation {
    condition     = can(regex("^(vip|sni-only|static-ip)$", var.ssl_support_method))
    error_message = "Invalid value for ssl_support_method. Must be one of vip, sni-only, or static-ip."
  }
}

variable "staging" {
  description = "(Optional) Whether the distribution is in a staging environment. Default is false."
  type        = bool
  default     = false
}

variable "wait_for_deployment" {
  description = "(Optional) If enabled, the resource will wait for the distribution status to change from InProgress to Deployed. Setting this to false will skip the process. Default is true."
  type        = bool
  default     = true
}

variable "web_acl_id" {
  description = "(Optional) The AWS WAF WebACL to associate with this distribution."
  type        = string
  default     = null
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) Map of tags to assign to the device."
  type        = map(any)
  default = {
    created_by  = "terraform" # Your name goes here
    terraform   = "true"
    environment = "prod"
  }
}