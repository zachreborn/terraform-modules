"""Regression tests for protected migration values and subprocess cancellation."""

import copy
import json
import os
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from contextlib import ExitStack
from pathlib import Path

import verify_adoption as verifier


def mapping_change():
    """Return a valid mapping address-only transition."""
    values = {
        "maximum_batching_window_in_seconds": 5,
        "function_response_types": ["ReportBatchItemFailures"],
    }
    return {
        "address": "module.mapping.aws_lambda_event_source_mapping.this",
        "type": "aws_lambda_event_source_mapping",
        "mode": "managed",
        "change": {
            "actions": ["update"],
            "before": values,
            "after": copy.deepcopy(values),
            "after_unknown": {},
        },
    }


class MigrationPropertiesTest(unittest.TestCase):
    """Reject protected drift while allowing narrowly scoped computed repairs."""

    def test_unchanged_values(self):
        """Accept an unchanged address-only transition."""
        item = mapping_change()
        verifier.assert_transition({"resource_changes": [item]}, [item["address"]], {})

    def test_every_configurable_field_is_protected(self):
        """Mutating any protected field must fail verification."""
        for resource_type, attributes in verifier.CONFIGURABLE.items():
            for attribute in attributes:
                if attribute in {"tags", "policy"}:
                    continue
                with self.subTest(resource_type=resource_type, attribute=attribute):
                    item = mapping_change()
                    item["type"] = resource_type
                    item["change"]["before"] = {attribute: None}
                    item["change"]["after"] = {
                        attribute: json.dumps("changed") if attribute == "redrive_policy" else "changed",
                    }
                    with self.assertRaisesRegex(AssertionError, attribute):
                        verifier.assert_configurable_properties(item)

    def test_partial_response_removal(self):
        """Removing partial responses is not an allowed in-place repair."""
        item = mapping_change()
        item["change"]["after"]["function_response_types"] = []
        with self.assertRaisesRegex(AssertionError, "function_response_types"):
            verifier.assert_transition({"resource_changes": [item]}, [item["address"]], {})

    def test_batching_window_reset(self):
        """Resetting the batching window is not an allowed repair."""
        item = mapping_change()
        item["change"]["after"]["maximum_batching_window_in_seconds"] = 0
        with self.assertRaisesRegex(AssertionError, "maximum_batching_window"):
            verifier.assert_transition({"resource_changes": [item]}, [item["address"]], {})

    def test_unknown_configured_value(self):
        """An unknown protected result must not silently pass."""
        item = mapping_change()
        item["change"]["after_unknown"]["function_response_types"] = True
        with self.assertRaisesRegex(AssertionError, "became unknown"):
            verifier.assert_configurable_properties(item)

    def test_allowed_tag_repair_and_computed_identifier(self):
        """Allow tag repairs without freezing computed-only identifiers."""
        item = mapping_change()
        item["change"]["after"].update({"tags": {"Name": "fixed"}, "arn": None})
        item["change"]["after_unknown"]["arn"] = True
        verifier.assert_configurable_properties(item)

    def test_computed_encryption_key_only(self):
        """Ignore only the computed key, not the encryption setting."""
        item = mapping_change()
        item["type"] = "aws_dynamodb_table"
        item["change"]["before"] = {
            "server_side_encryption": [{"enabled": True, "kms_key_arn": "computed"}],
        }
        item["change"]["after"] = {
            "server_side_encryption": [{"enabled": True, "kms_key_arn": None}],
        }
        item["change"]["after_unknown"] = {
            "server_side_encryption": [{"kms_key_arn": True}],
        }
        verifier.assert_configurable_properties(item)
        item["change"]["after"]["server_side_encryption"][0]["enabled"] = False
        with self.assertRaisesRegex(AssertionError, "server_side_encryption"):
            verifier.assert_configurable_properties(item)


class TerminationTest(unittest.TestCase):
    """Exercise SIGTERM against a real isolated command and its child."""

    def test_handler_restored(self):
        """Leave the embedding process's signal handler unchanged."""
        previous = signal.getsignal(signal.SIGTERM)
        with verifier.termination_cleanup():
            self.assertNotEqual(signal.getsignal(signal.SIGTERM), previous)
        self.assertEqual(signal.getsignal(signal.SIGTERM), previous)

    def test_sigterm_reaps_command_group(self):
        """Cancel the wrapper and verify both isolated descendants stop."""
        with tempfile.TemporaryDirectory(prefix="verifier-sigterm-") as temporary, ExitStack() as processes:
            root = Path(temporary)
            tool = root / "fake-engine"
            pids_file = root / "pids.json"
            tool.write_text(
                f"#!{sys.executable}\n"
                "import json, os, subprocess, sys, time\n"
                "from pathlib import Path\n"
                "child = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(60)'])\n"
                f"Path({str(pids_file)!r}).write_text(json.dumps([os.getpid(), child.pid]))\n"
                "time.sleep(60)\n",
            )
            tool.chmod(0o700)
            program = (
                "import sys; from pathlib import Path; "
                f"sys.path.insert(0, {str(verifier.HERE)!r}); "
                "import verify_adoption as v\n"
                "with v.termination_cleanup():\n"
                "    v.run(sys.argv[1], Path(sys.argv[2]), [], 30)\n"
            )
            process = processes.enter_context(
                subprocess.Popen(
                    [sys.executable, "-B", "-c", program, str(tool), str(root)],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                ),
            )
            pids = []
            try:
                deadline = time.monotonic() + 10
                while not pids_file.exists() and time.monotonic() < deadline:
                    time.sleep(0.05)
                self.assertTrue(pids_file.exists(), "Fake engine must start before cancellation.")
                pids = json.loads(pids_file.read_text())
                process.terminate()
                process.communicate(timeout=10)
                self.assertEqual(process.returncode, 143)
                for pid in pids:
                    result = subprocess.run(
                        ["ps", "-o", "stat=", "-p", str(pid)],
                        capture_output=True,
                        text=True,
                        check=False,
                    )
                    self.assertTrue(
                        not result.stdout.strip() or result.stdout.strip().startswith("Z"),
                        f"Command/provider process {pid} survived cancellation.",
                    )
            finally:
                if process.poll() is None:
                    process.kill()
                    process.communicate()
                if pids:
                    try:
                        os.killpg(pids[0], signal.SIGKILL)
                    except ProcessLookupError:
                        pass


if __name__ == "__main__":
    unittest.main()
