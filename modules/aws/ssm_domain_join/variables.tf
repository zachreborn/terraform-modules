variable "domain_name" {
  type        = string
  description = "(Required) FQDN of the domain to join, e.g. slfcu.local."
}

variable "dns_servers" {
  type        = list(string)
  description = "(Required) DC IPs the joined instance should use for DNS resolution."
}

variable "secret_arn" {
  type        = string
  description = "(Required) ARN of the Secrets Manager secret holding join credentials. JSON-shaped {\"username\":\"...\",\"password\":\"...\"}. Cross-account ARNs supported."
}

variable "instance_role_name" {
  type        = string
  description = "(Required) Name of the EC2 IAM role to grant secretsmanager:GetSecretValue on secret_arn."
}

variable "target_tag_value" {
  type        = string
  description = "(Required) EC2 tag value used to opt instances into auto-join, e.g. slfcu.local."
}

variable "target_tag_key" {
  type        = string
  description = "(Optional) EC2 tag key used to opt instances into auto-join."
  default     = "ad_join"
}

variable "name" {
  type        = string
  description = "(Optional) Name prefix for the SSM document and association."
  default     = "ssm-domain-join"
}

variable "tags" {
  type        = map(any)
  description = "(Optional) Tags applied to the SSM document."
  default     = {}
}
