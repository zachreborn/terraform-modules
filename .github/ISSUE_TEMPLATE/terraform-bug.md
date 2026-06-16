---
name: Bug
about: Report a bug in an existing module.
title: 'bug: <short description>'
labels: bug
assignees: zachreborn
---

### Affected module path

<!-- Required. Provide the path to the module, e.g. modules/aws/ec2_instance -->

### Tool and provider versions

<!-- Required. List the OpenTofu or Terraform version and the relevant provider versions. -->

- OpenTofu / Terraform version:
- AWS (or other) provider version:

### Describe the bug

<!-- Required. A clear and concise description of what the bug is. -->

### Reproduction steps

<!-- Required. Minimal steps to reproduce the behavior. -->

1. <!-- e.g. Add the following module block to main.tf ... -->
2. <!-- e.g. Run `tofu init && tofu plan` -->
3. <!-- e.g. Observe the error -->
<!-- Add or remove steps as needed -->

### Expected behavior

<!-- Required. What did you expect to happen? -->

### Actual behavior

<!-- Required. What actually happened? -->

### Error / stack trace / plan output

<!-- Required. Paste the full error message, stack trace, or relevant plan/apply output. -->

```hcl
# Paste the full error message, stack trace, or plan/apply output here.
# Do not truncate — the triage agent reads the full output.
```

### Acceptance criteria

<!-- Required. How will we know this bug is fixed? List specific, verifiable conditions. -->

- [ ] <!-- e.g. `tofu apply` completes without error on the affected module -->
- [ ] <!-- e.g. The previously failing resource is created/updated as expected -->

### Additional context

<!-- Optional. Workarounds, related issues, screenshots, etc. -->
