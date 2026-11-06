"""Offline lifecycle tests using synthetic state; never plans against live AWS."""

import json
import os
import shutil
import subprocess
import tempfile
import unittest
import uuid
from pathlib import Path

MODULE = Path(__file__).resolve().parents[1]
STACK_ARN = "arn:aws:cloudformation:us-west-2:123456789012:stack/test-stack/test-id"
ROLE_ARN = "arn:aws:iam::123456789012:role/rubrik"
TEMPLATE = '{"Resources":{}}'
POLICY = '{"Statement":[]}'


class ProtectedStackLifecycleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tofu = os.environ.get("TOFU_BINARY") or shutil.which("tofu")
        if not cls.tofu:
            raise RuntimeError("Set TOFU_BINARY or add tofu to PATH.")
        cls.temporary = tempfile.TemporaryDirectory(prefix="protected-stack-tests-")
        cls.addClassCleanup(cls.temporary.cleanup)
        cls.directory = Path(cls.temporary.name)
        for path in MODULE.glob("*.tf"):
            shutil.copy2(path, cls.directory / path.name)
        lockfile = MODULE / ".terraform.lock.hcl"
        if lockfile.exists():
            shutil.copy2(lockfile, cls.directory / lockfile.name)
        (cls.directory / "offline_provider.tf").write_text(
            """
provider "aws" {
  region                      = "us-west-2"
  skip_credentials_validation = true
  skip_region_validation      = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  endpoints {
    cloudformation = "http://localhost:9"
    sts            = "http://localhost:9"
  }
}
""",
            encoding="utf-8",
        )
        empty_credentials = cls.directory / "empty-credentials"
        empty_credentials.write_text("", encoding="utf-8")
        cls.environment = {
            key: value
            for key, value in os.environ.items()
            if not key.startswith(("AWS_", "TF_VAR_", "TF_CLI_ARGS"))
            and key not in {"TF_DATA_DIR", "TF_WORKSPACE"}
        }
        cls.environment.update(
            {
                "AWS_ACCESS_KEY_ID": "offline-" + uuid.uuid4().hex,
                "AWS_SECRET_ACCESS_KEY": uuid.uuid4().hex,
                "AWS_CONFIG_FILE": str(empty_credentials),
                "AWS_SHARED_CREDENTIALS_FILE": str(empty_credentials),
                "AWS_EC2_METADATA_DISABLED": "true",
                "TF_IN_AUTOMATION": "true",
            }
        )
        init_args = ["init", "-backend=false", "-input=false", "-no-color"]
        plugins = MODULE / ".terraform" / "providers"
        if plugins.exists():
            init_args.append(f"-plugin-dir={plugins}")
        result = cls.invoke(*init_args)
        if result.returncode:
            raise RuntimeError(result.stdout + result.stderr)

    @classmethod
    def invoke(cls, *arguments):
        return subprocess.run(
            [cls.tofu, f"-chdir={cls.directory}", *arguments],
            env=cls.environment,
            capture_output=True,
            text=True,
            timeout=120,
            check=False,
        )

    def setUp(self):
        self.variables = {
            "name": "test-stack",
            "region": "us-west-2",
            "template_body": TEMPLATE,
            "policy_body": POLICY,
            "parameters": {},
            "capabilities": [],
            "notification_arns": [],
            "on_failure": "ROLLBACK",
        }
        attributes = {
            "id": STACK_ARN,
            "name": "test-stack",
            "region": "us-west-2",
            "template_body": TEMPLATE,
            "template_url": None,
            "policy_body": POLICY,
            "policy_url": None,
            "capabilities": [],
            "notification_arns": [],
            "disable_rollback": False,
            "on_failure": "ROLLBACK",
            "iam_role_arn": None,
            "parameters": {},
            "timeout_in_minutes": 60,
            "timeouts": {"create": None, "update": None, "delete": None},
            "tags": {"Name": "test-stack"},
            "tags_all": {"Name": "test-stack"},
            "outputs": {"RoleARN": ROLE_ARN},
        }
        state = {
            "version": 4,
            "terraform_version": "1.8.0",
            "serial": 1,
            "lineage": str(uuid.uuid4()),
            "outputs": {},
            "resources": [
                {
                    "mode": "managed",
                    "type": "aws_cloudformation_stack",
                    "name": "this",
                    "provider": 'provider["registry.opentofu.org/hashicorp/aws"]',
                    "instances": [
                        {
                            "schema_version": 0,
                            "attributes": attributes,
                            "sensitive_attributes": [],
                        }
                    ],
                }
            ],
        }
        (self.directory / "terraform.tfstate").write_text(
            json.dumps(state), encoding="utf-8"
        )

    def plan(self, *arguments):
        (self.directory / "inputs.tfvars.json").write_text(
            json.dumps(self.variables), encoding="utf-8"
        )
        return self.invoke(
            "plan",
            "-refresh=false",
            "-input=false",
            "-no-color",
            "-var-file=inputs.tfvars.json",
            *arguments,
        )

    def assert_protected(self, result):
        self.assertEqual(result.returncode, 1, result.stdout + result.stderr)
        self.assertIn("prevent_destroy", result.stderr)
        self.assertIn("Resource instance cannot be destroyed", result.stderr)

    def test_baseline_and_every_output(self):
        result = self.plan("-out=baseline.tfplan")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        shown = self.invoke("show", "-json", "baseline.tfplan")
        self.assertEqual(shown.returncode, 0, shown.stderr)
        plan = json.loads(shown.stdout)
        changes = plan["resource_changes"]
        self.assertTrue(changes)
        self.assertTrue(all(item["change"]["actions"] == ["no-op"] for item in changes))
        outputs = plan["planned_values"]["outputs"]
        self.assertEqual(outputs["id"]["value"], STACK_ARN)
        self.assertEqual(outputs["name"]["value"], "test-stack")
        self.assertEqual(outputs["outputs"]["value"], {"RoleARN": ROLE_ARN})
        self.assertEqual(outputs["tags_all"]["value"], {"Name": "test-stack"})

    def test_destroy_is_rejected(self):
        self.assert_protected(self.plan("-destroy"))

    def test_name_replacement_is_rejected(self):
        self.variables["name"] = "replacement-stack"
        self.assert_protected(self.plan())

    def test_creation_timeout_replacement_is_rejected(self):
        self.variables["timeout_in_minutes"] = 120
        self.assert_protected(self.plan())

    def test_rollback_replacement_is_rejected(self):
        self.variables["on_failure"] = "DO_NOTHING"
        self.assert_protected(self.plan())

    def test_template_update_remains_allowed(self):
        self.variables["template_body"] = '{"Resources":{},"Description":"Updated"}'
        result = self.plan("-out=update.tfplan")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        shown = self.invoke("show", "-json", "update.tfplan")
        self.assertEqual(shown.returncode, 0, shown.stderr)
        plan = json.loads(shown.stdout)
        stack = next(
            item
            for item in plan["resource_changes"]
            if item["address"] == "aws_cloudformation_stack.this"
        )
        self.assertEqual(stack["change"]["actions"], ["update"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
