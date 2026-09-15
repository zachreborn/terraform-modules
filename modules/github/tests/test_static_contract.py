#!/usr/bin/env python3
"""Verify safety clauses that plan values cannot expose."""

import re
from pathlib import Path

MODULE_MAIN = Path(__file__).resolve().parents[1] / "main.tf"
MODULE_VARIABLES = Path(__file__).resolve().parents[1] / "variables.tf"
SOURCE = MODULE_MAIN.read_text(encoding="utf-8")
VARIABLE_SOURCE = MODULE_VARIABLES.read_text(encoding="utf-8")


def resource_body(resource_type: str, resource_name: str) -> str:
    """Return the body of a named resource block."""
    match = re.search(
        rf'resource "{re.escape(resource_type)}" '
        rf'"{re.escape(resource_name)}" \{{(?P<body>.*?)\n\}}',
        SOURCE,
        re.DOTALL,
    )
    if match is None:
        raise AssertionError(f"Missing {resource_type}.{resource_name} resource")
    return match.group("body")


repository = resource_body("github_repository", "this")
lifecycle_ok = re.search(
    r"lifecycle\s*\{\s*prevent_destroy\s*=\s*true\s*\}",
    repository,
    re.DOTALL,
)
assert lifecycle_ok, "github_repository.this must set lifecycle.prevent_destroy"

msg = "Normalized collections must be deduplicated and sorted"
assert "sort(distinct([" in SOURCE, msg

msg = "Repository topics must be lowercased and trimmed"
assert "lower(trimspace(topic))" in SOURCE, msg

msg = "Supplemental status-check names must be trimmed"
assert "trimspace(check)" in SOURCE, msg

msg = "Supplemental rulesets must never render bypass actors"
assert "bypass_actors {" not in SOURCE, msg

fork_optional = re.findall(
    r"^\s*fork\s*=\s*optional\(string\)$",
    VARIABLE_SOURCE,
    re.MULTILINE,
)
msg = "Profile and override fork inputs must match provider string schema"
assert len(fork_optional) == 2, msg

repository_arguments = {
    "name",
    "description",
    "homepage_url",
    "fork",
    "source_owner",
    "source_repo",
    "private",
    "visibility",
    "topics",
    "has_issues",
    "has_projects",
    "has_wiki",
    "has_discussions",
    "has_downloads",
    "is_template",
    "allow_merge_commit",
    "allow_squash_merge",
    "allow_rebase_merge",
    "allow_auto_merge",
    "allow_forking",
    "allow_update_branch",
    "delete_branch_on_merge",
    "web_commit_signoff_required",
    "squash_merge_commit_title",
    "squash_merge_commit_message",
    "merge_commit_title",
    "merge_commit_message",
    "vulnerability_alerts",
    "ignore_vulnerability_alerts_during_read",
    "auto_init",
    "gitignore_template",
    "license_template",
    "default_branch",
    "archived",
    "archive_on_destroy",
}
for argument in repository_arguments:
    matched = re.search(rf"^\s*{argument}\s*=", repository, re.MULTILINE)
    msg = f"github_repository.this must wire provider argument {argument}"
    assert matched, msg

for block in ("pages", "security_and_analysis", "template"):
    matched = re.search(rf'dynamic "{block}"\s*\{{', repository)
    msg = f"github_repository.this must render provider block {block}"
    assert matched, msg
