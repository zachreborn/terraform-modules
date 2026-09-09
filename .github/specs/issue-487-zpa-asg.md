# Spec: ZPA App Connector ASG module
**Issue:** #487
**Status:** Spec approved — implementation complete in PR (pending)
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
Sunward needs replaceable ZPA App Connectors with ASG rolling replace, Marketplace RHEL 9 AMI, SSM agent install, and first-boot host OS updates. Existing fixed-instance module remains for Gen2 cutover.

## 2. Non-goals
- General-purpose AWS ASG module
- ZPA portal API automation for stale connector cleanup
- Multi-AZ SSM VPC endpoints (consumer responsibility)

## 3. Affected module path(s)
- `modules/aws/vendor/zscaler/zpa_asg/` (new)

## 4. Proposed design
### `variables.tf`
vpc_id, subnet_ids, name, provisioning_key, iam_instance_profile, key_name, ami_id, sizes, termination_policies, max_instance_lifetime, enable_ssm_agent, enable_host_os_update, encrypted (default false for Marketplace AMI), tags

### `outputs.tf`
security_group_id/arn, launch_template_id/arn/latest_version, ami_id, asg_name/arn/min/max/desired

### `main.tf`
data.aws_ami el9 marketplace; aws_security_group egress-only; aws_launch_template; aws_autoscaling_group; optional aws_autoscaling_policy CPU target

## 5. Breaking-change assessment
- Breaking: no

## 6. Checkov / tfsec considerations
- Egress 0.0.0.0/0 ignored (ZPA outbound-only connectors)
- encrypted default false with tfsec ignore (Marketplace pre-encrypted AMI)

## 7. terraform-docs impact
Yes — new module README docs block

## 8. Testing
- tofu test: baseline plan, cpu tracking branch, ami override, validation failures

## 9. Open questions
None

## 10. Acceptance criteria
Mirror issue #487 acceptance criteria.
