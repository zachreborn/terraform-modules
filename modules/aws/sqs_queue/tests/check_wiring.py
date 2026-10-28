"""Inspect real child attributes from native mock states, never live state.

Native tests cannot traverse private resources inside module.kms. This
supplement checks those resources in tofu test's structured mock output rather
than mocking away the child or expanding the public interface for tests.
Run from any directory: python3 <module>/tests/check_wiring.py.
"""

import json
import os
import signal
import subprocess
import tempfile
from pathlib import Path

MODULE = Path(__file__).resolve().parents[1]
SQS_CONTEXT_KEY = "kms:EncryptionContext:aws:sqs:arn"
SQS_QUEUE_ARN = "arn:aws:sqs:us-east-1:123456789012:work"
INPUT_ERROR = "Invalid value for input variable"
LEGACY_DESCRIPTION = "CloudTrail kms key used to encrypt audit logs"


def check(condition, message):
    """Require a precise wiring or diagnostic condition."""
    if not condition:
        raise AssertionError(message)


def resources(module):
    """Collect configured and computed attributes from the entire mock state."""
    result = {item["address"]: item["values"] for item in module.get("resources", [])}
    for child in module.get("child_modules", []):
        result.update(resources(child))
    return result


def events(stdout):
    """Yield structured events while ignoring non-JSON diagnostic lines."""
    for line in stdout.splitlines():
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(event, dict):
            yield event


def run_test(*arguments):
    """Run bounded mocked tests and reap the command and provider children."""
    with subprocess.Popen(
        ["tofu", f"-chdir={MODULE}", "test", "-json", *arguments],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        start_new_session=True,
    ) as process:
        try:
            stdout, _ = process.communicate(timeout=180)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.communicate(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.communicate()
            raise AssertionError("Mock test exceeded its 180-second budget.") from None
        except BaseException:
            os.killpg(process.pid, signal.SIGKILL)
            process.communicate()
            raise
        return process.returncode, list(events(stdout))


def check_invalid_numeric_strings():
    """Require type-conversion diagnostics for every malformed numeric input."""
    variables = [
        "delay_seconds",
        "visibility_timeout_seconds",
        "message_retention_seconds",
        "kms_data_key_reuse_period_seconds",
        "max_message_size",
        "receive_wait_time_seconds",
        "key_deletion_window_in_days",
    ]
    with tempfile.TemporaryDirectory(prefix=".type-tests-", dir=MODULE) as folder:
        for variable in variables:
            Path(folder, f"{variable}.tftest.hcl").write_text(
                'mock_provider "aws" {}\n'
                'variables {\n  name = "work"\n  create_kms_key = false\n'
                f'  {variable} = "invalid-number"\n'
                '}\nrun "invalid_type" { command = plan }\n'
            )
        code, output = run_test(f"-test-directory={Path(folder).name}")
        failures = set()
        for event in output:
            if event.get("type") != "diagnostic":
                continue
            if event.get("diagnostic", {}).get("summary") == INPUT_ERROR:
                failures.add(Path(event["@testfile"]).stem.replace(".tftest", ""))
        check(code != 0, "Malformed numeric strings must fail type conversion.")
        check(
            failures == set(variables),
            "Every numeric input must reject malformed strings with a type diagnostic.",
        )


def mock_states(output):
    """Index emitted mocked apply states by their exact run names."""
    states = {}
    for event in output:
        if event.get("type") == "test_state":
            states[event["@testrun"]] = event["test_state"]
    return states


def main():
    """Verify actual child wiring, complete policies and numeric type failures."""
    code, output = run_test("-verbose", "-filter=tests/wiring.tftest.hcl")
    check(code == 0, "Native wiring mock suite must pass before state inspection.")
    states = mock_states(output)
    check(
        set(states) == {"legacy_created_key_defaults", "legacy_key_overrides"},
        "Both real-child mock applies must emit structured state.",
    )
    for name, state in states.items():
        actual = resources(state["values"]["root_module"])
        key = actual["module.kms[0].aws_kms_key.this"]
        alias = actual["module.kms[0].aws_kms_alias.this"]
        queue = actual["aws_sqs_queue.queue"]
        overrides = name == "legacy_key_overrides"
        expected = {
            "customer_master_key_spec": "SYMMETRIC_DEFAULT",
            "description": "Queue encryption" if overrides else LEGACY_DESCRIPTION,
            "deletion_window_in_days": 7 if overrides else 30,
            "enable_key_rotation": not overrides,
            "is_enabled": not overrides,
            "key_usage": "ENCRYPT_DECRYPT",
            "tags": {"Name": "caller" if overrides else "work"},
        }
        # With no configured region the mock invents computed region values;
        # it does not execute the provider's default-region behavior. Check the
        # explicit path exactly, and leave computed defaults to native mocks.
        if overrides:
            expected["region"] = "us-west-2"
        for attribute, value in expected.items():
            check(key[attribute] == value, f"{name}: key {attribute} wiring differs.")
        check(
            alias["name_prefix"] == ("alias/work_" if overrides else "alias/sqs_key_")
            and alias["target_key_id"] == key["key_id"]
            and (not overrides or alias["region"] == "us-west-2"),
            f"{name}: alias prefix/target/region wiring differs.",
        )
        check(
            queue["kms_master_key_id"] == key["arn"],
            f"{name}: queue does not use the real child key ARN.",
        )
        policy = json.loads(key["policy"])
        if overrides:
            expected_policy = {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Effect": "Allow",
                        "Principal": {"AWS": "arn:aws:iam::123456789012:root"},
                        "Action": "kms:*",
                        "Resource": "*",
                    }
                ],
            }
        else:
            expected_policy = {
                "Version": "2012-10-17",
                "Statement": [
                    {
                        "Sid": "EnableAccountAdministration",
                        "Effect": "Allow",
                        "Principal": {"AWS": "arn:aws:iam::123456789012:root"},
                        "Action": "kms:*",
                        "Resource": "*",
                    },
                    {
                        "Sid": "AllowQueueServiceUse",
                        "Effect": "Allow",
                        "Principal": {"AWS": "arn:aws:iam::123456789012:root"},
                        "Action": ["kms:Decrypt", "kms:GenerateDataKey"],
                        "Resource": "*",
                        "Condition": {
                            "StringEquals": {
                                "kms:CallerAccount": "123456789012",
                                "kms:ViaService": "sqs.us-east-1.amazonaws.com",
                            },
                            "ArnLike": {
                                SQS_CONTEXT_KEY: SQS_QUEUE_ARN,
                            },
                        },
                    },
                ],
            }
        check(policy == expected_policy, f"{name}: child key policy wiring differs.")
    print(
        "PASS: 2 real-child mocked states; all legacy key, alias and policy attributes.",
    )
    check_invalid_numeric_strings()
    print("PASS: 7 malformed numeric strings rejected at the type-conversion boundary.")


if __name__ == "__main__":
    main()
