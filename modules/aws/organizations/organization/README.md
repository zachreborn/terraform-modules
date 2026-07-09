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
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">AWS Organization Module</h3>
  <p align="center">
    This module generates and manages an AWS Organization.
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

### Composed Module

If you need the Organization itself, its OUs, and its member accounts all managed together from one YAML file, use [`modules/aws/organizations`](..) instead of calling this module directly — it wires this module together with [`modules/aws/organizations/ou`](../ou) and [`modules/aws/organizations/account`](../account), including defaulting a bare top-level OU's `parent_id` to this module's root. This module remains fully usable standalone (as shown below).

Already using this module alongside `ou`/`account` and upgrading from v8? See the
[migration guide](../MIGRATION.md) for both options: keep the three modules separate, or consolidate
into the composed module.

### Simple Example

This example creates an AWS Organization with the default settings, including
`enabled_policy_types` defaulting to `["SERVICE_CONTROL_POLICY"]` so the SCPs
enabled by default below (Identity Center deny, Leave Organization deny, Root
Access Key Creation deny) work out of the box.

```
module "organization" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/organization"

    aws_service_access_principals = [
        "aws-artifact-account-sync.amazonaws.com",
        "backup.amazonaws.com",
        "cloudtrail.amazonaws.com",
        "sso.amazonaws.com",
    ]
}
```

If you override `enabled_policy_types` yourself (for example to add
`TAG_POLICY`), make sure `"SERVICE_CONTROL_POLICY"` stays in the list unless
you've also disabled the default SCPs (see below), since an explicit override
replaces the default entirely rather than merging with it.

### Identity Center Service Control Policy

By default this module creates and attaches a Service Control Policy (SCP) to the
organization root which denies `sso:CreateInstance` organization-wide. This
prevents member (child) accounts from creating their own account-level IAM
Identity Center (AWS SSO) instances, keeping Identity Center management
centralized in the management account / delegated administrator.

**Prerequisite:** SCP support must be enabled on the organization --
`enabled_policy_types` defaults to `["SERVICE_CONTROL_POLICY"]` so this works
out of the box. If you override `enabled_policy_types`, keep
`"SERVICE_CONTROL_POLICY"` in the list or the apply fails with a precondition
error. The organization `feature_set` must be `ALL`.

```
module "organization" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/organization"

    # Optional: add TAG_POLICY on top of the default SERVICE_CONTROL_POLICY.
    enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]

    # The following are the defaults and may be omitted.
    enable_identity_center_scp = true
    attach_identity_center_scp = true
}
```

To opt out entirely (no new resources, clean plan), set
`enable_identity_center_scp = false`. To create the policy without enforcing it,
set `attach_identity_center_scp = false`. To attach the SCP to specific OUs or
accounts instead of the organization root, set `identity_center_scp_target_ids`.

### Region Restriction Service Control Policy

This module can optionally create and attach a Service Control Policy (SCP) that
denies regional AWS service actions outside an approved list of Regions
(`allowed_regions`), leaving global/non-regional services (IAM, STS,
Organizations, Route 53, CloudFront, WAF/Shield, billing, etc.) usable. The
built-in `NotAction` exemption list is modeled on the AWS Control Tower Region
deny control (`CT.MULTISERVICE.PV.1` / `GRREGIONDENY`) and lives in
`policies/deny_regions_scp.json`.

This feature is **opt-in** (`enable_region_scp` defaults to `false`) because
there is no Region allow-list that is safe to assume for every caller. When
enabled you must supply a non-empty `allowed_regions`.

**Prerequisites and cautions:**

- SCP support must be enabled on the organization: `enabled_policy_types`
  defaults to `["SERVICE_CONTROL_POLICY"]`, so this works out of the box. If you
  override `enabled_policy_types`, keep `"SERVICE_CONTROL_POLICY"` in the list
  (and `feature_set` must be `ALL`), otherwise the apply fails with a
  precondition error.
- SCPs **never apply to the organization management (payer) account**, so the
  management account is not restricted by this policy regardless of attachment.
- `us-east-1` is commonly required even for non-primary workloads because some
  global features (CloudFront, ACM for CloudFront, IAM console flows, etc.) route
  through it. Include it in `allowed_regions` unless you are certain you do not
  need it. The module does **not** auto-inject it.
- Roll this out via a **Sandbox / non-production OU** (using
  `region_scp_target_ids`) and verify before attaching to Production or the
  organization root. Confirm `region_scp_exempted_principal_arns` covers your
  break-glass and cross-Region automation roles first.

```
module "organization" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/organization"

    # Optional: add TAG_POLICY on top of the default SERVICE_CONTROL_POLICY.
    enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]

    enable_region_scp = true
    allowed_regions   = ["us-east-1", "us-west-2"]

    # Optional: exempt break-glass / execution roles from the deny.
    region_scp_exempted_principal_arns = [
        "arn:aws:iam::*:role/AWSControlTowerExecution",
        "arn:aws:iam::*:role/OrganizationAccountAccessRole",
    ]

    # Optional: allow additional global-service actions beyond the built-in list.
    region_scp_exempted_actions = ["pricingplanmanager:*"]

    # Optional: attach to specific OUs/accounts instead of the organization root.
    # region_scp_target_ids = ["ou-abcd-11111111"]
}
```

To create the policy without enforcing it, set `attach_region_scp = false`. To
leave the feature off entirely (default), omit `enable_region_scp` or set it to
`false`.

### Deny Leave Organization Service Control Policy

By default this module creates and attaches a Service Control Policy (SCP) to the
organization root which denies `organizations:LeaveOrganization`. This prevents
member accounts from removing themselves from the organization, which would
otherwise let them escape every other guardrail (SCPs, centralized logging,
delegated administration) enforced by this module.

**Prerequisite:** SCP support must be enabled on the organization --
`enabled_policy_types` defaults to `["SERVICE_CONTROL_POLICY"]` so this works
out of the box. If you override `enabled_policy_types`, keep
`"SERVICE_CONTROL_POLICY"` in the list or the apply fails with a precondition
error. The organization `feature_set` must be `ALL`.

```
module "organization" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/organization"

    # Optional: add TAG_POLICY on top of the default SERVICE_CONTROL_POLICY.
    enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]

    # The following are the defaults and may be omitted.
    enable_leave_organization_scp = true
    attach_leave_organization_scp = true
}
```

To opt out entirely (no new resources, clean plan), set
`enable_leave_organization_scp = false`. To create the policy without enforcing
it, set `attach_leave_organization_scp = false`. To attach the SCP to specific
OUs or accounts instead of the organization root, set
`leave_organization_scp_target_ids`.

### Deny Root Access Key Creation Service Control Policy

By default this module creates and attaches a Service Control Policy (SCP) to the
organization root which denies `iam:CreateAccessKey` for the account root user
(matched via `aws:PrincipalArn` `StringLike` `arn:aws:iam::*:root`). This
prevents member accounts from minting long-lived root user access keys, one of
the highest-risk credentials in an AWS account, mirroring AWS Control Tower's
strongly-recommended "Disallow Creation of Access Keys for the Root User"
control.

**Prerequisite:** SCP support must be enabled on the organization --
`enabled_policy_types` defaults to `["SERVICE_CONTROL_POLICY"]` so this works
out of the box. If you override `enabled_policy_types`, keep
`"SERVICE_CONTROL_POLICY"` in the list or the apply fails with a precondition
error. The organization `feature_set` must be `ALL`.

```
module "organization" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/organization"

    # Optional: add TAG_POLICY on top of the default SERVICE_CONTROL_POLICY.
    enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]

    # The following are the defaults and may be omitted.
    enable_root_access_key_scp = true
    attach_root_access_key_scp = true
}
```

To opt out entirely (no new resources, clean plan), set
`enable_root_access_key_scp = false`. To create the policy without enforcing it,
set `attach_root_access_key_scp = false`. To attach the SCP to specific OUs or
accounts instead of the organization root, set `root_access_key_scp_target_ids`.

### Deny Security Service Tampering Service Control Policy

This module can optionally create and attach a Service Control Policy (SCP) that
denies the actions used to stop, disable, or delete the centralized security
services this module already integrates via `aws_service_access_principals`:
CloudTrail, AWS Config, GuardDuty, and Security Hub.

This feature is **opt-in** (`enable_security_services_scp` defaults to `false`)
because a delegated administrator or audit automation role may legitimately need
to manage these services, and should be exempted first via
`security_services_scp_exempted_principal_arns` before this SCP is attached
broadly.

```
module "organization" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/organization"

    # Required so the SCP can be created and attached.
    enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]

    enable_security_services_scp = true

    # Optional: exempt delegated-administrator / break-glass roles from the deny.
    security_services_scp_exempted_principal_arns = [
        "arn:aws:iam::*:role/DelegatedSecurityAdminRole",
        "arn:aws:iam::*:role/AWSControlTowerExecution",
    ]
}
```

To create the policy without enforcing it, set
`attach_security_services_scp = false`. To leave the feature off entirely
(default), omit `enable_security_services_scp` or set it to `false`.

### Deny Root User Actions Service Control Policy

This module can optionally create and attach a Service Control Policy (SCP) that
denies all actions taken by the account root user in member accounts, except a
built-in allowlist covering the AWS-documented tasks that require root user
credentials (S3 bucket-policy and MFA Delete recovery, SQS queue-policy
recovery, billing/Support-plan changes, and EC2 Reserved Instance Marketplace
seller registration -- see [Tasks that require root user
credentials](https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-tasks.html)).
The deny **does not** apply to short-lived, task-scoped root sessions created
via AWS's centralized root access feature (`sts:AssumeRoot` from the management
account or a delegated administrator) -- those are matched with the
`aws:AssumedRoot` condition key and are already scoped by their own AWS managed
task policy, so centralized root credential management and S3/SQS policy-unlock
sessions keep working.

This feature is **opt-in** (`enable_root_actions_scp` defaults to `false`)
because the built-in allowlist deliberately does **not** exempt broad `iam:*`
actions for the "restore IAM user permissions if the only administrator is
locked out" scenario -- exempting that would defeat the purpose of the SCP.
Add IAM actions to `root_actions_scp_exempted_actions` yourself if you want that
break-glass path and accept the reduced guarantee.

```
module "organization" {
    source = "github.com/zachreborn/terraform-modules//modules/aws/organizations/organization"

    # Required so the SCP can be created and attached.
    enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]

    enable_root_actions_scp = true

    # Optional: allow additional root-only actions beyond the built-in list.
    root_actions_scp_exempted_actions = ["support:*"]
}
```

To create the policy without enforcing it, set `attach_root_actions_scp = false`.
To leave the feature off entirely (default), omit `enable_root_actions_scp` or
set it to `false`. Roll this out via a Sandbox / non-production OU and confirm
your break-glass and centralized-root-access workflows first, consistent with
the rollout guidance for the Region-restriction SCP above.

#### Break Glass Procedures

**SCPs never apply to the organization management account**, regardless of
which targets they're attached to. This is an AWS platform guarantee, not
something this module controls, so the management account's root user and IAM
principals always retain full access as a last resort.

If any SCP created by this module (this one or another) is blocking a
legitimate action in a **member** account and you need immediate relief:

1. **Centralized root access (fastest, no drift).** The Deny Root User Actions
   SCP's condition exempts `aws:AssumedRoot`, so task-scoped root sessions
   started with `aws sts assume-root` from the management account or a
   delegated administrator bypass the deny entirely and require no policy
   changes. This only works if centralized root access has already been
   enabled in the organization.
2. **Detach or update the SCP directly (immediate, causes drift).** An admin in
   the management account can run `aws organizations detach-policy` or
   `update-policy` right now, via the console or CLI, independent of Terraform.
   Follow up promptly with a matching code change (step 3) -- otherwise the
   next `tofu apply` recreates/reattaches the policy exactly as defined in
   code.
3. **Disable via Terraform (durable fix).** Set the relevant `enable_*_scp`
   variable to `false` (removes the policy) or `attach_*_scp` to `false`
   (keeps the policy defined but detaches it), then apply. This is the
   long-term, drift-free fix and should always follow an emergency detach.
4. **Non-root IAM principals are unaffected.** The Deny Root User Actions
   SCP's condition matches only the account root user ARN -- IAM roles and
   users, including whatever role runs your Terraform pipeline, are never
   denied by it, so step 3 remains available even while the SCP is enforced.

### Centralized Security Services

The default `aws_service_access_principals` enables AWS Organizations trusted
access for the centralized security services this module library integrates
with: Security Hub (both Security Hub CSPM and the unified Security Hub),
GuardDuty, Config, IAM Access Analyzer, and Inspector. Keeping these in the
organization module makes it the single source of truth for trusted access, so
the delegated-administrator modules (`security_hub/organization`,
`guardduty/organization`, `config/organization`, etc.) do not enable a principal
out-of-band and cause perpetual drift on the next apply of this module.

**Caveat:** once a service has a registered delegated administrator, AWS will not
let you remove its principal from this list until the delegated administrator is
deregistered. Remove the delegated-administrator resource first, then drop the
principal.

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.78.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.78.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_centralized_backup"></a> [centralized\_backup](#module\_centralized\_backup) | ../policy | n/a |
| <a name="module_centralized_root"></a> [centralized\_root](#module\_centralized\_root) | ../../iam/organizations_features | n/a |
| <a name="module_identity_center_scp"></a> [identity\_center\_scp](#module\_identity\_center\_scp) | ../policy | n/a |
| <a name="module_leave_organization_scp"></a> [leave\_organization\_scp](#module\_leave\_organization\_scp) | ../policy | n/a |
| <a name="module_region_scp"></a> [region\_scp](#module\_region\_scp) | ../policy | n/a |
| <a name="module_root_access_key_scp"></a> [root\_access\_key\_scp](#module\_root\_access\_key\_scp) | ../policy | n/a |
| <a name="module_root_actions_scp"></a> [root\_actions\_scp](#module\_root\_actions\_scp) | ../policy | n/a |
| <a name="module_security_services_scp"></a> [security\_services\_scp](#module\_security\_services\_scp) | ../policy | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_organizations_organization.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_organization) | resource |
| [aws_organizations_policy_attachment.identity_center_scp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_organizations_policy_attachment.leave_organization_scp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_organizations_policy_attachment.region_scp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_organizations_policy_attachment.root_access_key_scp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_organizations_policy_attachment.root_actions_scp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |
| [aws_organizations_policy_attachment.security_services_scp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/organizations_policy_attachment) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_allowed_regions"></a> [allowed\_regions](#input\_allowed\_regions) | (Required when enable\_region\_scp is true) List of AWS Regions where regional service actions remain allowed (e.g. ["us-east-1", "us-west-2"]). Used as the aws:RequestedRegion StringNotEquals value in the Region-deny SCP. Consider including us-east-1 because some global features route through it. Ignored when enable\_region\_scp is false. | `list(string)` | `[]` | no |
| <a name="input_attach_identity_center_scp"></a> [attach\_identity\_center\_scp](#input\_attach\_identity\_center\_scp) | (Optional) If true, attaches the Identity Center deny SCP to the targets in identity\_center\_scp\_target\_ids (defaulting to the organization root). When false, the policy is created but not attached. Defaults to true. | `bool` | `true` | no |
| <a name="input_attach_leave_organization_scp"></a> [attach\_leave\_organization\_scp](#input\_attach\_leave\_organization\_scp) | (Optional) If true, attaches the Deny Leave Organization SCP to the targets in leave\_organization\_scp\_target\_ids (defaulting to the organization root). When false, the policy is created but not attached. Defaults to true. | `bool` | `true` | no |
| <a name="input_attach_region_scp"></a> [attach\_region\_scp](#input\_attach\_region\_scp) | (Optional) If true, attaches the Region-deny SCP to the targets in region\_scp\_target\_ids (defaulting to the organization root). When false, the policy is created but not attached. Defaults to true. | `bool` | `true` | no |
| <a name="input_attach_root_access_key_scp"></a> [attach\_root\_access\_key\_scp](#input\_attach\_root\_access\_key\_scp) | (Optional) If true, attaches the Deny Root Access Key Creation SCP to the targets in root\_access\_key\_scp\_target\_ids (defaulting to the organization root). When false, the policy is created but not attached. Defaults to true. | `bool` | `true` | no |
| <a name="input_attach_root_actions_scp"></a> [attach\_root\_actions\_scp](#input\_attach\_root\_actions\_scp) | (Optional) If true, attaches the Deny Root User Actions SCP to the targets in root\_actions\_scp\_target\_ids (defaulting to the organization root). When false, the policy is created but not attached. Defaults to true. | `bool` | `true` | no |
| <a name="input_attach_security_services_scp"></a> [attach\_security\_services\_scp](#input\_attach\_security\_services\_scp) | (Optional) If true, attaches the Deny Security Service Tampering SCP to the targets in security\_services\_scp\_target\_ids (defaulting to the organization root). When false, the policy is created but not attached. Defaults to true. | `bool` | `true` | no |
| <a name="input_aws_service_access_principals"></a> [aws\_service\_access\_principals](#input\_aws\_service\_access\_principals) | (Optional) List of AWS service principal names for which you want to enable trusted access (integration) with your organization. This is typically in the form of a URL, such as service-abbreviation.amazonaws.com. Organization must have feature\_set set to ALL. The default list enables the centralized security services this module library integrates with (Security Hub, GuardDuty, Config, IAM Access Analyzer, and Inspector) so that their delegated-administrator modules do not create trusted-access drift. Note: once a service has a registered delegated administrator, removing its principal from this list will fail until the delegated administrator is deregistered. For additional information, see the AWS Organizations User Guide. | `list(string)` | <pre>[<br/>  "access-analyzer.amazonaws.com",<br/>  "account.amazonaws.com",<br/>  "aws-artifact-account-sync.amazonaws.com",<br/>  "backup.amazonaws.com",<br/>  "cloudtrail.amazonaws.com",<br/>  "config.amazonaws.com",<br/>  "guardduty.amazonaws.com",<br/>  "health.amazonaws.com",<br/>  "inspector2.amazonaws.com",<br/>  "securityhub.amazonaws.com",<br/>  "sso.amazonaws.com"<br/>]</pre> | no |
| <a name="input_enable_identity_center_scp"></a> [enable\_identity\_center\_scp](#input\_enable\_identity\_center\_scp) | (Optional) If true, creates a Service Control Policy (SCP) which denies sso:CreateInstance organization-wide so member accounts cannot create account-level IAM Identity Center instances. Defaults to true. Requires SERVICE\_CONTROL\_POLICY in enabled\_policy\_types. | `bool` | `true` | no |
| <a name="input_enable_leave_organization_scp"></a> [enable\_leave\_organization\_scp](#input\_enable\_leave\_organization\_scp) | (Optional) If true, creates a Service Control Policy (SCP) which denies organizations:LeaveOrganization organization-wide so member accounts cannot remove themselves from the organization. Defaults to true. Requires SERVICE\_CONTROL\_POLICY in enabled\_policy\_types. | `bool` | `true` | no |
| <a name="input_enable_organization_backup"></a> [enable\_organization\_backup](#input\_enable\_organization\_backup) | (Optional) If true, enables the organization backup policy. Defaults to false. | `bool` | `false` | no |
| <a name="input_enable_region_scp"></a> [enable\_region\_scp](#input\_enable\_region\_scp) | (Optional) If true, creates a Service Control Policy (SCP) which denies regional AWS service actions outside the Regions listed in allowed\_regions (global/non-regional services are exempted via NotAction). Opt-in: defaults to false so existing callers see no change until they enable it. Requires SERVICE\_CONTROL\_POLICY in enabled\_policy\_types. | `bool` | `false` | no |
| <a name="input_enable_root_access_key_scp"></a> [enable\_root\_access\_key\_scp](#input\_enable\_root\_access\_key\_scp) | (Optional) If true, creates a Service Control Policy (SCP) which denies iam:CreateAccessKey for the account root user organization-wide, preventing creation of long-lived root user access keys in member accounts. Defaults to true. Requires SERVICE\_CONTROL\_POLICY in enabled\_policy\_types. | `bool` | `true` | no |
| <a name="input_enable_root_actions_scp"></a> [enable\_root\_actions\_scp](#input\_enable\_root\_actions\_scp) | (Optional) If true, creates a Service Control Policy (SCP) which denies all actions taken by the account root user in member accounts, except the actions in root\_actions\_scp\_exempted\_actions. Opt-in: defaults to false because an overly narrow exemption list can lock out legitimate root-only recovery flows; test in a non-production OU before wider rollout. Requires SERVICE\_CONTROL\_POLICY in enabled\_policy\_types. | `bool` | `false` | no |
| <a name="input_enable_security_services_scp"></a> [enable\_security\_services\_scp](#input\_enable\_security\_services\_scp) | (Optional) If true, creates a Service Control Policy (SCP) which denies actions that stop, disable, or delete CloudTrail, AWS Config, GuardDuty, and Security Hub in member accounts. Opt-in: defaults to false so existing callers see no change until they enable it, and so delegated-administrator/audit roles can be exempted first via security\_services\_scp\_exempted\_principal\_arns. Requires SERVICE\_CONTROL\_POLICY in enabled\_policy\_types. | `bool` | `false` | no |
| <a name="input_enabled_features"></a> [enabled\_features](#input\_enabled\_features) | A list of IAM organization features which will be enabled. Valid values are RootCredentialsManagement and RootSessions. | `list(string)` | <pre>[<br/>  "RootCredentialsManagement",<br/>  "RootSessions"<br/>]</pre> | no |
| <a name="input_enabled_policy_types"></a> [enabled\_policy\_types](#input\_enabled\_policy\_types) | (Optional) List of Organizations policy types to enable in the Organization Root. Organization must have feature\_set set to ALL. Defaults to ["SERVICE\_CONTROL\_POLICY"] so the SCPs this module enables by default (Identity Center deny, Leave Organization deny, Root Access Key Creation deny) work out of the box without callers needing to set this explicitly. Override with a list that includes "SERVICE\_CONTROL\_POLICY" if you also need other policy types (e.g. ["SERVICE\_CONTROL\_POLICY", "TAG\_POLICY"]), or set enable\_identity\_center\_scp/enable\_leave\_organization\_scp/enable\_root\_access\_key\_scp to false and this to [] if you don't want SCP support enabled at all. For additional information about valid policy types (e.g., AISERVICES\_OPT\_OUT\_POLICY, BACKUP\_POLICY, SERVICE\_CONTROL\_POLICY, and TAG\_POLICY), see the AWS Organizations API Reference. | `list(string)` | <pre>[<br/>  "SERVICE_CONTROL_POLICY"<br/>]</pre> | no |
| <a name="input_feature_set"></a> [feature\_set](#input\_feature\_set) | (Optional) Specify 'ALL' (default) or 'CONSOLIDATED\_BILLING'. | `string` | `"ALL"` | no |
| <a name="input_identity_center_scp_description"></a> [identity\_center\_scp\_description](#input\_identity\_center\_scp\_description) | (Optional) Description of the Identity Center deny SCP. | `string` | `"Denies sso:CreateInstance org-wide so member accounts cannot create account-level IAM Identity Center instances."` | no |
| <a name="input_identity_center_scp_name"></a> [identity\_center\_scp\_name](#input\_identity\_center\_scp\_name) | (Optional) Name of the Identity Center deny SCP. Used as the name of the aws\_organizations\_policy created via the policy module. | `string` | `"DenyMemberAccountIdentityCenter"` | no |
| <a name="input_identity_center_scp_target_ids"></a> [identity\_center\_scp\_target\_ids](#input\_identity\_center\_scp\_target\_ids) | (Optional) List of organization root, OU, or account IDs to attach the Identity Center deny SCP to. When null and attach\_identity\_center\_scp is true, the SCP is attached to the organization root. Defaults to null. | `list(string)` | `null` | no |
| <a name="input_leave_organization_scp_description"></a> [leave\_organization\_scp\_description](#input\_leave\_organization\_scp\_description) | (Optional) Description of the Deny Leave Organization SCP. | `string` | `"Denies organizations:LeaveOrganization org-wide so member accounts cannot remove themselves from the organization."` | no |
| <a name="input_leave_organization_scp_name"></a> [leave\_organization\_scp\_name](#input\_leave\_organization\_scp\_name) | (Optional) Name of the Deny Leave Organization SCP. Used as the name of the aws\_organizations\_policy created via the policy module. | `string` | `"DenyLeaveOrganization"` | no |
| <a name="input_leave_organization_scp_target_ids"></a> [leave\_organization\_scp\_target\_ids](#input\_leave\_organization\_scp\_target\_ids) | (Optional) List of organization root, OU, or account IDs to attach the Deny Leave Organization SCP to. When null and attach\_leave\_organization\_scp is true, the SCP is attached to the organization root. Defaults to null. | `list(string)` | `null` | no |
| <a name="input_region_scp_description"></a> [region\_scp\_description](#input\_region\_scp\_description) | (Optional) Description of the Region-deny SCP. | `string` | `"Denies regional AWS service actions outside the approved Regions in var.allowed_regions, exempting global services."` | no |
| <a name="input_region_scp_exempted_actions"></a> [region\_scp\_exempted\_actions](#input\_region\_scp\_exempted\_actions) | (Optional) Additional actions merged into the built-in global-service NotAction list, for callers who depend on global services not covered out of the box (e.g. ["pricingplanmanager:*"]). Defaults to []. | `list(string)` | `[]` | no |
| <a name="input_region_scp_exempted_principal_arns"></a> [region\_scp\_exempted\_principal\_arns](#input\_region\_scp\_exempted\_principal\_arns) | (Optional) List of IAM principal ARNs (wildcards allowed, e.g. arn:aws:iam::*:role/BreakGlassRole) excluded from the Region deny via an ArnNotLike condition on aws:PrincipalARN, so break-glass / execution roles are not locked out. When empty, no ArnNotLike condition is added. Defaults to []. | `list(string)` | `[]` | no |
| <a name="input_region_scp_name"></a> [region\_scp\_name](#input\_region\_scp\_name) | (Optional) Name of the Region-deny SCP. Used as the name of the aws\_organizations\_policy created via the policy module. | `string` | `"DenyAccessOutsideApprovedRegions"` | no |
| <a name="input_region_scp_target_ids"></a> [region\_scp\_target\_ids](#input\_region\_scp\_target\_ids) | (Optional) List of organization root, OU, or account IDs to attach the Region-deny SCP to. When null and attach\_region\_scp is true, the SCP is attached to the organization root. Defaults to null. | `list(string)` | `null` | no |
| <a name="input_root_access_key_scp_description"></a> [root\_access\_key\_scp\_description](#input\_root\_access\_key\_scp\_description) | (Optional) Description of the Deny Root Access Key Creation SCP. | `string` | `"Denies iam:CreateAccessKey for the account root user org-wide so member accounts cannot create long-lived root user access keys."` | no |
| <a name="input_root_access_key_scp_name"></a> [root\_access\_key\_scp\_name](#input\_root\_access\_key\_scp\_name) | (Optional) Name of the Deny Root Access Key Creation SCP. Used as the name of the aws\_organizations\_policy created via the policy module. | `string` | `"DenyRootAccessKeyCreation"` | no |
| <a name="input_root_access_key_scp_target_ids"></a> [root\_access\_key\_scp\_target\_ids](#input\_root\_access\_key\_scp\_target\_ids) | (Optional) List of organization root, OU, or account IDs to attach the Deny Root Access Key Creation SCP to. When null and attach\_root\_access\_key\_scp is true, the SCP is attached to the organization root. Defaults to null. | `list(string)` | `null` | no |
| <a name="input_root_actions_scp_description"></a> [root\_actions\_scp\_description](#input\_root\_actions\_scp\_description) | (Optional) Description of the Deny Root User Actions SCP. | `string` | `"Denies all actions taken by the account root user in member accounts, except the built-in and caller-supplied exempted actions."` | no |
| <a name="input_root_actions_scp_exempted_actions"></a> [root\_actions\_scp\_exempted\_actions](#input\_root\_actions\_scp\_exempted\_actions) | (Optional) Additional actions merged into the built-in NotAction allowlist so legitimate root-only actions are not denied. The built-in list already covers the AWS-documented tasks that require root user credentials and are not exempted via the aws:AssumedRoot condition (S3 bucket-policy and MFA Delete recovery, SQS queue-policy recovery, billing/Support-plan changes, and EC2 Reserved Instance Marketplace seller registration). It deliberately does NOT exempt broad iam:* actions for the 'restore IAM user permissions if locked out' scenario -- add iam actions here yourself if you want that break-glass path. Defaults to []. | `list(string)` | `[]` | no |
| <a name="input_root_actions_scp_name"></a> [root\_actions\_scp\_name](#input\_root\_actions\_scp\_name) | (Optional) Name of the Deny Root User Actions SCP. Used as the name of the aws\_organizations\_policy created via the policy module. | `string` | `"DenyRootUserActions"` | no |
| <a name="input_root_actions_scp_target_ids"></a> [root\_actions\_scp\_target\_ids](#input\_root\_actions\_scp\_target\_ids) | (Optional) List of organization root, OU, or account IDs to attach the Deny Root User Actions SCP to. When null and attach\_root\_actions\_scp is true, the SCP is attached to the organization root. Defaults to null. | `list(string)` | `null` | no |
| <a name="input_security_services_scp_description"></a> [security\_services\_scp\_description](#input\_security\_services\_scp\_description) | (Optional) Description of the Deny Security Service Tampering SCP. | `string` | `"Denies actions that stop, disable, or delete CloudTrail, AWS Config, GuardDuty, and Security Hub in member accounts."` | no |
| <a name="input_security_services_scp_exempted_principal_arns"></a> [security\_services\_scp\_exempted\_principal\_arns](#input\_security\_services\_scp\_exempted\_principal\_arns) | (Optional) List of IAM principal ARNs (wildcards allowed, e.g. arn:aws:iam::*:role/DelegatedSecurityAdminRole) excluded from the deny via an ArnNotLike condition on aws:PrincipalARN, so delegated-administrator, break-glass, or automation roles that legitimately manage these security services are not locked out. When empty, no ArnNotLike condition is added. Defaults to []. | `list(string)` | `[]` | no |
| <a name="input_security_services_scp_name"></a> [security\_services\_scp\_name](#input\_security\_services\_scp\_name) | (Optional) Name of the Deny Security Service Tampering SCP. Used as the name of the aws\_organizations\_policy created via the policy module. | `string` | `"DenySecurityServiceTampering"` | no |
| <a name="input_security_services_scp_target_ids"></a> [security\_services\_scp\_target\_ids](#input\_security\_services\_scp\_target\_ids) | (Optional) List of organization root, OU, or account IDs to attach the Deny Security Service Tampering SCP to. When null and attach\_security\_services\_scp is true, the SCP is attached to the organization root. Defaults to null. | `list(string)` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to the AWS Organization. Tags are key-value pairs that help organize and manage resources. | `map(string)` | <pre>{<br/>  "terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_accounts"></a> [accounts](#output\_accounts) | List of organization accounts.All elements have these attributes: arn, email, id, name, status. |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the organization |
| <a name="output_id"></a> [id](#output\_id) | ID of the organization |
| <a name="output_identity_center_scp_arn"></a> [identity\_center\_scp\_arn](#output\_identity\_center\_scp\_arn) | ARN of the Identity Center deny SCP, or null when enable\_identity\_center\_scp is false. |
| <a name="output_identity_center_scp_attachment_target_ids"></a> [identity\_center\_scp\_attachment\_target\_ids](#output\_identity\_center\_scp\_attachment\_target\_ids) | List of target IDs the Identity Center deny SCP was attached to. Empty when attachment is disabled. |
| <a name="output_identity_center_scp_id"></a> [identity\_center\_scp\_id](#output\_identity\_center\_scp\_id) | ID of the Identity Center deny SCP, or null when enable\_identity\_center\_scp is false. |
| <a name="output_leave_organization_scp_arn"></a> [leave\_organization\_scp\_arn](#output\_leave\_organization\_scp\_arn) | ARN of the Deny Leave Organization SCP, or null when enable\_leave\_organization\_scp is false. |
| <a name="output_leave_organization_scp_attachment_target_ids"></a> [leave\_organization\_scp\_attachment\_target\_ids](#output\_leave\_organization\_scp\_attachment\_target\_ids) | List of target IDs the Deny Leave Organization SCP was attached to. Empty when attachment is disabled. |
| <a name="output_leave_organization_scp_id"></a> [leave\_organization\_scp\_id](#output\_leave\_organization\_scp\_id) | ID of the Deny Leave Organization SCP, or null when enable\_leave\_organization\_scp is false. |
| <a name="output_master_account_arn"></a> [master\_account\_arn](#output\_master\_account\_arn) | ARN of the master account |
| <a name="output_master_account_email"></a> [master\_account\_email](#output\_master\_account\_email) | Email address of the master account |
| <a name="output_master_account_id"></a> [master\_account\_id](#output\_master\_account\_id) | ID of the master account |
| <a name="output_region_scp_arn"></a> [region\_scp\_arn](#output\_region\_scp\_arn) | ARN of the Region-deny SCP, or null when enable\_region\_scp is false. |
| <a name="output_region_scp_attachment_target_ids"></a> [region\_scp\_attachment\_target\_ids](#output\_region\_scp\_attachment\_target\_ids) | List of target IDs the Region-deny SCP was attached to. Empty when attachment or creation is disabled. |
| <a name="output_region_scp_id"></a> [region\_scp\_id](#output\_region\_scp\_id) | ID of the Region-deny SCP, or null when enable\_region\_scp is false. |
| <a name="output_root_access_key_scp_arn"></a> [root\_access\_key\_scp\_arn](#output\_root\_access\_key\_scp\_arn) | ARN of the Deny Root Access Key Creation SCP, or null when enable\_root\_access\_key\_scp is false. |
| <a name="output_root_access_key_scp_attachment_target_ids"></a> [root\_access\_key\_scp\_attachment\_target\_ids](#output\_root\_access\_key\_scp\_attachment\_target\_ids) | List of target IDs the Deny Root Access Key Creation SCP was attached to. Empty when attachment is disabled. |
| <a name="output_root_access_key_scp_id"></a> [root\_access\_key\_scp\_id](#output\_root\_access\_key\_scp\_id) | ID of the Deny Root Access Key Creation SCP, or null when enable\_root\_access\_key\_scp is false. |
| <a name="output_root_actions_scp_arn"></a> [root\_actions\_scp\_arn](#output\_root\_actions\_scp\_arn) | ARN of the Deny Root User Actions SCP, or null when enable\_root\_actions\_scp is false. |
| <a name="output_root_actions_scp_attachment_target_ids"></a> [root\_actions\_scp\_attachment\_target\_ids](#output\_root\_actions\_scp\_attachment\_target\_ids) | List of target IDs the Deny Root User Actions SCP was attached to. Empty when attachment or creation is disabled. |
| <a name="output_root_actions_scp_id"></a> [root\_actions\_scp\_id](#output\_root\_actions\_scp\_id) | ID of the Deny Root User Actions SCP, or null when enable\_root\_actions\_scp is false. |
| <a name="output_roots"></a> [roots](#output\_roots) | List of organization roots.All elements have these attributes: arn, id, name, policy\_types. |
| <a name="output_security_services_scp_arn"></a> [security\_services\_scp\_arn](#output\_security\_services\_scp\_arn) | ARN of the Deny Security Service Tampering SCP, or null when enable\_security\_services\_scp is false. |
| <a name="output_security_services_scp_attachment_target_ids"></a> [security\_services\_scp\_attachment\_target\_ids](#output\_security\_services\_scp\_attachment\_target\_ids) | List of target IDs the Deny Security Service Tampering SCP was attached to. Empty when attachment or creation is disabled. |
| <a name="output_security_services_scp_id"></a> [security\_services\_scp\_id](#output\_security\_services\_scp\_id) | ID of the Deny Security Service Tampering SCP, or null when enable\_security\_services\_scp is false. |
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
