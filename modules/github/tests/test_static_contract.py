#!/usr/bin/env python3
"""Verify safety and deterministic-normalization clauses that plan values cannot expose."""

from pathlib import Path
import re


MODULE_MAIN = Path(__file__).resolve().parents[1] / "main.tf"
SOURCE = MODULE_MAIN.read_text(encoding="utf-8")


def resource_body(resource_type: str, resource_name: str) -> str:
    match = re.search(
        rf'resource "{re.escape(resource_type)}" "{re.escape(resource_name)}" \{{(?P<body>.*?)\n\}}',
        SOURCE,
        re.DOTALL,
    )
    if match is None:
        raise AssertionError(f"Missing {resource_type}.{resource_name} resource")
    return match.group("body")


repository = resource_body("github_repository", "this")
assert re.search(
    r"lifecycle\s*\{\s*prevent_destroy\s*=\s*true\s*\}",
    repository,
    re.DOTALL,
), "github_repository.this must always set lifecycle.prevent_destroy to true"

assert "sort(distinct([" in SOURCE, "Normalized collections must be deduplicated and sorted"
assert "lower(trimspace(topic))" in SOURCE, "Repository topics must be lowercased and trimmed"
assert "trimspace(check)" in SOURCE, "Supplemental status-check names must be trimmed"
assert "bypass_actors {" not in SOURCE, "Supplemental rulesets must never render bypass actors"

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
    assert re.search(rf"^\s*{argument}\s*=", repository, re.MULTILINE), (
        f"github_repository.this must wire the provider argument {argument}"
    )

for block in {"pages", "security_and_analysis", "template"}:
    assert re.search(rf'dynamic "{block}"\s*\{{', repository), (
        f"github_repository.this must render the provider block {block}"
    )
