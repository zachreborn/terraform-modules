"""Offline wiring and same-root synthetic migration checks for issue #537.

Run after module initialization: python3 tests/verify_adoption.py
Only native mocked tests apply; real-provider commands are refresh-disabled plans
with fake credentials and loopback endpoints. All state/plan files are temporary.
This verifies address-only transitions, not any consumer's production state.
"""

import argparse
import copy
import json
import os
import re
import signal
import subprocess
import tempfile
import uuid
from contextlib import contextmanager
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Thread

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[4]
API = HERE.parent
FIXTURE = HERE / "fixtures" / "issue_537_adoption"
NATIVE_INTEGRATION = "aws_apigatewayv2_integration.webhook"
STATE_SETTINGS = {"TF_DATA_DIR", "TF_WORKSPACE", "TOFU_DATA_DIR", "TOFU_WORKSPACE"}
ENV_PREFIXES = ("AWS_", "TF_VAR_", "TF_CLI_ARGS", "TOFU_CLI_ARGS")
DDB_TARGET = "DynamoDB_20120810.DescribeTable"
DDB_REQUEST = {"TableName": "webhook-events"}
MAPPING = "module.mapping."
KEYED_MAPPING = 'module.mapping["work"].'
NATIVE_ADDRESSES = {
    'module.tables.aws_dynamodb_table.this["webhook"]': "aws_dynamodb_table.webhook",
    "module.dlq.aws_sqs_queue.queue": "aws_sqs_queue.dlq",
    'module.queues["work"].aws_sqs_queue.queue': "aws_sqs_queue.work",
    "module.mapping.aws_lambda_event_source_mapping.this": "aws_lambda_event_source_mapping.work",
    "module.http.aws_apigatewayv2_api.this": "aws_apigatewayv2_api.webhook",
    'module.http.aws_apigatewayv2_integration.this["webhook"]': NATIVE_INTEGRATION,
    'module.http.aws_apigatewayv2_route.this["webhook"]': "aws_apigatewayv2_route.webhook",
    'module.http.aws_apigatewayv2_stage.this["$default"]': "aws_apigatewayv2_stage.webhook",
}

LEGACY_KEY_MOVES = {
    "module.queue.module.kms[0].aws_kms_key.this": "module.queue.aws_kms_key.sqs",
    "module.queue.module.kms[0].aws_kms_alias.this": "module.queue.aws_kms_alias.sqs",
    "module.queue.aws_sqs_queue.queue": "module.queue.aws_sqs_queue.queue",
}

# Only configurable attributes used by this fixture, never computed identifiers.
CONFIGURABLE = {
    "aws_dynamodb_table": [
        "name",
        "region",
        "billing_mode",
        "hash_key",
        "range_key",
        "attribute",
        "deletion_protection_enabled",
        "table_class",
        "stream_enabled",
        "ttl",
        "point_in_time_recovery",
        "server_side_encryption",
        "tags",
    ],
    "aws_sqs_queue": [
        "name",
        "region",
        "delay_seconds",
        "fifo_queue",
        "content_based_deduplication",
        "kms_master_key_id",
        "kms_data_key_reuse_period_seconds",
        "sqs_managed_sse_enabled",
        "message_retention_seconds",
        "max_message_size",
        "receive_wait_time_seconds",
        "visibility_timeout_seconds",
        "redrive_policy",
        "tags",
    ],
    "aws_lambda_event_source_mapping": [
        "region",
        "batch_size",
        "enabled",
        "event_source_arn",
        "function_name",
        "maximum_batching_window_in_seconds",
        "function_response_types",
        "use_resource_timeout_for_propagation",
        "tags",
    ],
    "aws_apigatewayv2_api": [
        "name",
        "region",
        "protocol_type",
        "api_key_selection_expression",
        "route_selection_expression",
        "disable_execute_api_endpoint",
        "fail_on_warnings",
        "tags",
    ],
    "aws_apigatewayv2_integration": [
        "api_id",
        "region",
        "integration_type",
        "integration_method",
        "integration_uri",
        "payload_format_version",
        "connection_type",
        "timeout_milliseconds",
    ],
    "aws_apigatewayv2_route": [
        "api_id",
        "region",
        "route_key",
        "authorization_type",
        "target",
    ],
    "aws_apigatewayv2_stage": [
        "api_id",
        "region",
        "name",
        "auto_deploy",
        "access_log_settings",
        "tags",
    ],
    "aws_kms_key": [
        "region",
        "customer_master_key_spec",
        "description",
        "deletion_window_in_days",
        "enable_key_rotation",
        "key_usage",
        "is_enabled",
        "policy",
        "tags",
    ],
    "aws_kms_alias": ["region", "name_prefix", "target_key_id"],
}


def check(condition, message):
    """Require the full expected fixture or migration condition."""
    if not condition:
        raise AssertionError(message)


def offline_environment():
    """Exclude live credentials and workspace overrides from child commands."""
    env = {
        key: value
        for key, value in os.environ.items()
        if not key.startswith(ENV_PREFIXES) and key not in STATE_SETTINGS
    }
    env.update(
        {
            "AWS_ACCESS_KEY_ID": "offline-testing",
            "AWS_SECRET_ACCESS_KEY": "offline-testing",
            "AWS_REGION": "us-east-1",
            "AWS_EC2_METADATA_DISABLED": "true",
            "AWS_ENDPOINT_URL": "http://localhost:1",
            "AWS_MAX_ATTEMPTS": "1",
            "AWS_CONFIG_FILE": os.devnull,
            "AWS_SHARED_CREDENTIALS_FILE": os.devnull,
            "TF_IN_AUTOMATION": "true",
            "TF_WORKSPACE": "default",
            "CHECKPOINT_DISABLE": "1",
        }
    )
    return env


def stop_process(process):
    """Stop the command's process group and reap it, including provider children."""
    try:
        os.killpg(process.pid, signal.SIGKILL)
    except ProcessLookupError:
        pass
    process.communicate()


def run(tool, root, arguments, timeout):
    """Execute a bounded offline command and reap its entire process group."""
    command = [tool, f"-chdir={root}", *arguments]
    print(f"Running: {tool} {root.name} {' '.join(arguments[:2])}", flush=True)
    with subprocess.Popen(
        command,
        start_new_session=True,
        env=offline_environment(),
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    ) as process:
        try:
            stdout, stderr = process.communicate(timeout=timeout)
        except subprocess.TimeoutExpired as error:
            stop_process(process)
            raise RuntimeError(
                f"Command exceeded {timeout}s: {tool} {arguments[0]}",
            ) from error
        except BaseException:
            stop_process(process)
            raise
        if process.returncode != 0:
            # Only fake fixture data enters these commands; bound diagnostics.
            diagnostic = "\n".join((stderr or stdout).splitlines()[-70:])
            raise RuntimeError(f"Command failed ({process.returncode}): {diagnostic}")
        return stdout


def resources(module):
    """Flatten all managed resources from serialized mock modules."""
    result = list(module.get("resources", []))
    for child in module.get("child_modules", []):
        result.extend(resources(child))
    return [item for item in result if item["mode"] == "managed"]


def snapshot(tool, root, test_filter, timeout):
    """Capture exactly one native mocked apply state as structured values."""
    events = run(
        tool,
        root,
        ["test", "-json", "-verbose", f"-filter={test_filter}"],
        timeout,
    )
    states = [
        event["test_state"]
        for line in events.splitlines()
        if line.startswith("{")
        for event in [json.loads(line)]
        if event.get("type") == "test_state"
    ]
    check(len(states) == 1, "Expected exactly one mocked apply state.")
    return resources(states[0]["values"]["root_module"])


def is_describe_request(target, request):
    """Accept only the exact fabricated table's DescribeTable request."""
    return target == DDB_TARGET and request == DDB_REQUEST


@contextmanager
def dynamodb_endpoint():
    """Model the one read made by existing-table CustomizeDiff, fail otherwise."""
    calls = []

    class Handler(BaseHTTPRequestHandler):
        """Reject every operation except the fabricated table description."""

        def log_message(self, *args, **kwargs):
            """Do not log request headers or dummy authorization."""

        # BaseHTTPRequestHandler dispatch requires this exact method name.
        def do_POST(self):  # pylint: disable=invalid-name
            """Accept only the exact synthetic table's read-only DescribeTable."""
            target = self.headers.get("X-Amz-Target", "")
            request = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
            calls.append((target, request))
            allowed = is_describe_request(target, request)
            self.send_response(200 if allowed else 400)
            self.send_header("Content-Type", "application/x-amz-json-1.0")
            self.end_headers()
            response = (
                {
                    "Table": {
                        "TableName": "webhook-events",
                        "TableStatus": "ACTIVE",
                        "TableArn": "arn:aws:dynamodb:us-east-1:123456789012:table/webhook-events",
                        "AttributeDefinitions": [
                            {"AttributeName": "pk", "AttributeType": "S"},
                        ],
                        "KeySchema": [{"AttributeName": "pk", "KeyType": "HASH"}],
                        "GlobalSecondaryIndexes": [],
                        "BillingModeSummary": {"BillingMode": "PAY_PER_REQUEST"},
                    }
                }
                if allowed
                else {
                    "__type": "UnsupportedOperation",
                    "message": "Unexpected offline request",
                }
            )
            self.wfile.write(json.dumps(response).encode())

    server = ThreadingHTTPServer(("localhost", 0), Handler)
    thread = Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        yield f"http://localhost:{server.server_port}"
        check(bool(calls), "Expected the real provider's plan-time DescribeTable read.")
        check(
            all(is_describe_request(*call) for call in calls),
            "The offline endpoint received an unexpected operation.",
        )
    finally:
        server.shutdown()
        server.server_close()
        thread.join()


def provider_configuration(endpoint="http://localhost:1"):
    """Disable account discovery and route every service to loopback only."""
    return {
        "region": "us-east-1",
        "skip_credentials_validation": True,
        "skip_requesting_account_id": True,
        "skip_metadata_api_check": True,
        "skip_region_validation": True,
        "max_retries": 0,
        "endpoints": [
            {
                name: endpoint
                for name in (
                    "dynamodb",
                    "sqs",
                    "lambda",
                    "apigatewayv2",
                    "kms",
                    "sts",
                    "iam",
                )
            }
        ],
    }


def write_provider(root, endpoint="http://localhost:1"):
    """Write the fail-closed provider configuration in a disposable root."""
    (root / "offline.tf.json").write_text(
        json.dumps(
            {
                "provider": {"aws": provider_configuration(endpoint)},
            }
        )
    )


def raw_state(items, renames):
    """Convert mock metadata to synthetic state while preserving identities."""
    result = []
    for item in items:
        address = renames.get(item["address"], item["address"])
        match = re.fullmatch(
            r"(?:(.*)\.)?([a-z0-9_]+)\.([a-z0-9_]+)(?:\[(.*)\])?",
            address,
        )
        check(match is not None, f"Unsupported fixture address: {address}")
        module, resource_type, name, index = match.groups()
        instance = {
            "schema_version": item["schema_version"],
            "attributes": item["values"],
            "sensitive_attributes": [],
        }
        if index is not None:
            instance["index_key"] = json.loads(index)
        resource = {
            "mode": "managed",
            "type": resource_type,
            "name": name,
            "provider": f'provider["{item["provider_name"]}"]',
            "instances": [instance],
        }
        if module:
            resource["module"] = module
        result.append(resource)
    return {
        "version": 4,
        "terraform_version": "1.9.0",
        "serial": 1,
        "lineage": str(uuid.uuid4()),
        "outputs": {},
        "resources": result,
    }


def native_configuration(items, renames):
    """Build the matching native baseline without computed-only arguments."""
    result = {}
    for item in items:
        address = renames[item["address"]]
        resource_type, name = address.rsplit(".", 1)
        values = item["values"]
        attrs = {}
        for key in CONFIGURABLE[resource_type]:
            if values.get(key) is not None:
                attrs[key] = copy.deepcopy(values[key])
        # JSON configuration represents repeatable nested blocks as arrays,
        # which is also their representation in the test's serialized state.
        if resource_type == "aws_sqs_queue":
            if attrs.get("kms_master_key_id"):
                attrs.pop("sqs_managed_sse_enabled", None)
            else:
                attrs.pop("kms_master_key_id", None)
                attrs.pop("kms_data_key_reuse_period_seconds", None)
            if not attrs.get("redrive_policy"):
                attrs.pop("redrive_policy", None)
        if resource_type == "aws_dynamodb_table":
            # This is provider-computed for the AWS-managed encryption mode,
            # not a caller-selected customer key.
            for encryption in attrs.get("server_side_encryption", []):
                encryption.pop("kms_key_arn", None)
        result.setdefault(resource_type, {})[name] = attrs
    return {"resource": result}


def plan(tool, root, timeout):
    """Initialize and inspect a refresh-disabled plan, never apply it."""
    run(tool, root, ["init", "-backend=false", "-input=false", "-no-color"], timeout)
    run(
        tool,
        root,
        [
            "plan",
            "-refresh=false",
            "-input=false",
            "-no-color",
            "-out=transition.plan",
        ],
        timeout,
    )
    return json.loads(run(tool, root, ["show", "-json", "transition.plan"], timeout))


def assert_transition(document, expected, moves):
    """Reject resource loss, incorrect moves and any create/delete/replace."""
    changes = []
    for change in document.get("resource_changes", []):
        if change["mode"] == "managed":
            changes.append(change)
    check(
        {item["address"] for item in changes} == set(expected),
        "Migration must retain exactly the expected managed resources.",
    )
    for item in changes:
        address = item["address"]
        actions = item["change"]["actions"]
        check(
            actions in (["no-op"], ["update"]),
            f"Unexpected destructive/creative action at {address}: {actions}",
        )
        check(
            item.get("previous_address") == moves.get(item["address"]),
            f"Missing or incorrect moved address at {address}.",
        )


def declarative_moves(moves):
    """Serialize every expected old-to-new address pair for OpenTofu."""
    return [{"from": old, "to": new} for new, old in moves.items()]


def keyed_address(address):
    """Select the keyed mapping address without changing other resources."""
    return address.replace(MAPPING, KEYED_MAPPING)


def adoption_transition(tool, items, timeout, keyed, endpoint):
    """Verify all eight native moves in one persistent synthetic root."""
    renames = dict(NATIVE_ADDRESSES)
    fixture = (FIXTURE / "main.tf").read_text()
    # Resolve original fixture sources before moving the root into a temp dir.
    fixture = re.sub(
        r'source\s*=\s*"(\.[^"]+)"',
        lambda match: f'source = "{(FIXTURE / match[1]).resolve().as_posix()}"',
        fixture,
    )
    destinations = list(renames)
    if keyed:
        destinations = [keyed_address(address) for address in destinations]
        fixture = fixture.replace(
            'module "mapping" {',
            'module "mapping" {\n  for_each = toset(["work"])',
        ).replace("module.mapping.", 'module.mapping["work"].')
    expected_moves = dict(zip(destinations, renames.values()))
    with tempfile.TemporaryDirectory(prefix="issue-537-adoption-") as temporary:
        root = Path(temporary).resolve()
        fixture = re.sub(
            r'source\s*=\s*"(/[^"]+)"',
            lambda match: f'source = "{os.path.relpath(match[1], root)}"',
            fixture,
        )
        write_provider(root, endpoint)
        state = raw_state(items, renames)
        state_path = root / "terraform.tfstate"
        state_path.write_text(json.dumps(state))
        native = root / "main.tf.json"
        native.write_text(json.dumps(native_configuration(items, renames)))
        assert_transition(plan(tool, root, timeout), renames.values(), {})
        native.unlink()
        (root / "main.tf").write_text(fixture)
        (root / "moves.tf.json").write_text(
            json.dumps(
                {
                    "moved": declarative_moves(expected_moves),
                }
            )
        )
        assert_transition(plan(tool, root, timeout), destinations, expected_moves)
        check(
            json.loads(state_path.read_text())["lineage"] == state["lineage"],
            "The migration must retain the same synthetic state lineage.",
        )
    print(
        f"PASS: eight native-to-module moves ({'keyed' if keyed else 'singleton'} mapping).",
    )


def assert_legacy_properties(document):
    """Freeze legacy configurable properties, allowing only policy/tag repairs."""
    protected = {
        "aws_kms_key": [
            "customer_master_key_spec",
            "description",
            "deletion_window_in_days",
            "enable_key_rotation",
            "key_usage",
            "is_enabled",
            "region",
        ],
        "aws_kms_alias": ["name", "name_prefix", "target_key_id", "region"],
        "aws_sqs_queue": [
            "name",
            "delay_seconds",
            "fifo_queue",
            "kms_master_key_id",
            "kms_data_key_reuse_period_seconds",
            "message_retention_seconds",
            "max_message_size",
            "receive_wait_time_seconds",
            "visibility_timeout_seconds",
            "region",
        ],
    }
    for change in document["resource_changes"]:
        if change["mode"] != "managed":
            continue
        for attribute in protected[change["type"]]:
            before = change["change"]["before"].get(attribute)
            after = change["change"]["after"].get(attribute)
            resource_type = change["type"]
            check(
                before == after,
                f"Legacy {resource_type}.{attribute} changed during the address move.",
            )


def kms_snapshot(tool, root, timeout, key_id, key_arn):
    """Capture exactly the actual queue, key and alias from mocked production."""
    mocks = {
        "aws_kms_key": {"defaults": {"id": key_id, "key_id": key_id, "arn": key_arn}},
        "aws_kms_alias": {
            "defaults": {
                "id": "alias/sqs_key_fixture",
                "name": "alias/sqs_key_fixture",
                "arn": "arn:aws:kms:us-east-1:123456789012:alias/sqs_key_fixture",
            }
        },
        "aws_sqs_queue": {
            "defaults": {
                "id": "https://sqs.us-east-1.amazonaws.com/123456789012/legacy-work",
                "url": "https://sqs.us-east-1.amazonaws.com/123456789012/legacy-work",
                "arn": "arn:aws:sqs:us-east-1:123456789012:legacy-work",
                "policy": "",
                "redrive_policy": "",
                "redrive_allow_policy": "",
            }
        },
    }
    test = root / "migration.tftest.json"
    test.write_text(
        json.dumps(
            {
                "mock_provider": {"aws": {"mock_resource": mocks}},
                "run": {"legacy_key_snapshot": {"command": "apply"}},
            }
        )
    )
    run(tool, root, ["init", "-backend=false", "-input=false", "-no-color"], timeout)
    items = snapshot(tool, root, test.name, timeout)

    check(len(items) == 3, "Legacy key mode must contain queue, key and alias only.")
    test.unlink()
    return items


def freeze_legacy_values(items, key_id, key_arn):
    """Seed legacy defaults independently so future regressions cannot pass."""
    # Independent defaults from 70973d55, not values learned from the new
    # implementation: a future default regression must fail this transition.
    for item in items:
        values = item["values"]
        if item["type"] == "aws_kms_key":
            values.update(
                {
                    "customer_master_key_spec": "SYMMETRIC_DEFAULT",
                    "description": "CloudTrail kms key used to encrypt audit logs",
                    "deletion_window_in_days": 30,
                    "enable_key_rotation": True,
                    "key_usage": "ENCRYPT_DECRYPT",
                    "is_enabled": True,
                    "tags": {},
                }
            )
        if item["type"] == "aws_sqs_queue":
            values.update(
                {
                    "name": "legacy-work",
                    "delay_seconds": 0,
                    "fifo_queue": False,
                    "kms_master_key_id": key_arn,
                    "kms_data_key_reuse_period_seconds": 300,
                    "message_retention_seconds": 345600,
                    "max_message_size": 262144,
                    "receive_wait_time_seconds": 0,
                    "visibility_timeout_seconds": 30,
                    "tags": {},
                }
            )
        if item["type"] == "aws_kms_alias":
            values.update({"name_prefix": "alias/sqs_key_", "target_key_id": key_id})


def legacy_native_configuration(items):
    """Build the legacy inline leaf at its original resource addresses."""
    names = {}
    for key, value in LEGACY_KEY_MOVES.items():
        names[key] = value.removeprefix("module.queue.")
    return native_configuration(items, names)


def kms_transition(tool, timeout):
    """Inspect the actual key moves against one unchanged synthetic state."""
    key_id = "11111111-2222-4333-8444-555555555555"
    key_arn = f"arn:aws:kms:us-east-1:123456789012:key/{key_id}"
    policy = json.dumps(
        {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "AWS": "arn:aws:iam::123456789012:root",
                    },
                    "Action": "kms:*",
                    "Resource": "*",
                }
            ],
        }
    )
    with tempfile.TemporaryDirectory(prefix="issue-537-kms-migration-") as temporary:
        root = Path(temporary).resolve()
        production = {
            "module": {
                "queue": {
                    "source": os.path.relpath(REPO / "modules/aws/sqs_queue", root),
                    "name": "legacy-work",
                    "region": "us-east-1",
                    "key_policy": policy,
                }
            }
        }
        configuration_file = root / "main.tf.json"
        configuration_file.write_text(json.dumps(production))
        items = kms_snapshot(tool, root, timeout, key_id, key_arn)
        freeze_legacy_values(items, key_id, key_arn)
        state = raw_state(items, LEGACY_KEY_MOVES)
        state_path = root / "terraform.tfstate"
        state_path.write_text(json.dumps(state))
        # Construct a legacy inline leaf from the captured actual resource
        # values; it retains old addresses and the original key/alias properties.
        legacy = root / "legacy"
        legacy.mkdir()
        (legacy / "main.tf.json").write_text(
            json.dumps(legacy_native_configuration(items)),
        )
        configuration_file.write_text(
            json.dumps({"module": {"queue": {"source": "./legacy"}}}),
        )
        write_provider(root)
        assert_transition(plan(tool, root, timeout), LEGACY_KEY_MOVES.values(), {})
        configuration_file.write_text(json.dumps(production))
        moves = {new: old for new, old in LEGACY_KEY_MOVES.items() if new != old}
        transition = plan(tool, root, timeout)
        assert_transition(transition, LEGACY_KEY_MOVES, moves)
        assert_legacy_properties(transition)
        check(
            json.loads(state_path.read_text())["lineage"] == state["lineage"],
            "KMS refactor must retain the same root and synthetic state.",
        )
    print("PASS: both production KMS moved declarations and unchanged queue address.")


def main():
    """Verify complete wiring and all singleton, keyed and legacy-key moves."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tool", choices=["tofu", "terraform"], default="tofu")
    parser.add_argument("--timeout", type=int, default=180)
    args = parser.parse_args()
    run(
        args.tool,
        API,
        ["init", "-backend=false", "-input=false", "-no-color"],
        args.timeout,
    )
    items = snapshot(args.tool, API, "tests/adoption.tftest.hcl", args.timeout)
    check(
        {item["address"] for item in items} == set(NATIVE_ADDRESSES),
        "Required fixture must contain exactly eight application resources and no keys.",
    )
    by_address = {item["address"]: item["values"] for item in items}
    work = by_address['module.queues["work"].aws_sqs_queue.queue']
    dlq = by_address["module.dlq.aws_sqs_queue.queue"]
    mapping = by_address["module.mapping.aws_lambda_event_source_mapping.this"]
    route = by_address['module.http.aws_apigatewayv2_route.this["webhook"]']
    integration = by_address['module.http.aws_apigatewayv2_integration.this["webhook"]']
    stage = by_address['module.http.aws_apigatewayv2_stage.this["$default"]']
    check(
        json.loads(work["redrive_policy"])
        == {
            "deadLetterTargetArn": dlq["arn"],
            "maxReceiveCount": 5,
        },
        "Work redrive must use the actual DLQ output and exact receive count.",
    )
    check(
        work["visibility_timeout_seconds"] == 720,
        "Work visibility must preserve consumer behavior.",
    )
    check(
        dlq["message_retention_seconds"] == 1209600,
        "Dead-letter retention must preserve consumer behavior.",
    )
    check(mapping["event_source_arn"] == work["arn"], "Mapping source must be wired.")
    check(
        route["target"] == "integrations/" + integration["id"],
        "Internal route reference must be wired.",
    )
    check(
        integration["payload_format_version"] == "2.0",
        "HTTP integration must preserve payload 2.0.",
    )
    check(
        integration["integration_method"] == "POST",
        "HTTP integration must preserve POST.",
    )
    check(stage["auto_deploy"] is True, "Default stage must auto-deploy.")
    print("PASS: eight application resources, zero keys, exact inter-module wiring.")
    with dynamodb_endpoint() as endpoint:
        adoption_transition(
            args.tool,
            copy.deepcopy(items),
            args.timeout,
            keyed=False,
            endpoint=endpoint,
        )
        adoption_transition(
            args.tool,
            copy.deepcopy(items),
            args.timeout,
            keyed=True,
            endpoint=endpoint,
        )
    kms_transition(args.tool, args.timeout)


if __name__ == "__main__":
    main()
