"""Bound provider lifetimes while OpenTofu issue #4694 remains unresolved.

After backend-disabled init, run: python3 run_opentofu_tests.py --module MODULE
Every root/tests native file runs exactly once in a fresh supervised process.
Keep stateful/dependent runs together; split only independent plan cases when a
file exceeds the 20-negative-case budget. No runtime rewriting or parser needed.
The conservative declaration count can reject unusual formatting/string content;
it must never silently omit tests or convert a failed invocation to success.
"""

import argparse
import re
from pathlib import Path

from resource_telemetry import emit, supervise

NEGATIVE_CASE_LIMIT = 20
SUFFIXES = (".tftest.hcl", ".tftest.json", ".tofutest.hcl", ".tofutest.json")
HCL_DECLARATION = r"(?m)^\s*expect_failures\s*="
JSON_DECLARATION = r'"expect_failures"\s*:'


def discover(module):
    """Match nonrecursive root/tests discovery and OpenTofu override precedence."""
    files = []
    for directory in (module, module / "tests"):
        if not directory.is_dir():
            continue
        for path in directory.iterdir():
            ignored = path.name.startswith((".", "#"))
            if not path.is_file() or ignored or not path.name.endswith(SUFFIXES):
                continue
            terraform_test = path.name.endswith((".tftest.hcl", ".tftest.json"))
            stem, _, extension = path.name.rpartition(".tftest.")
            override = path
            if terraform_test:
                override = path.with_name(f"{stem}.tofutest.{extension}")
            if terraform_test and override.is_file():
                continue
            files.append(path.relative_to(module))
    return sorted(files, key=lambda path: path.as_posix())


def preflight(module, files):
    """Fail before running any tests when an independent file needs partitioning."""
    if not files:
        raise ValueError("No native test files found")
    counts = []
    for path in files:
        text = (module / path).read_text(encoding="utf-8")
        pattern = JSON_DECLARATION if path.suffix == ".json" else HCL_DECLARATION
        count = len(re.findall(pattern, text))
        if count > NEGATIVE_CASE_LIMIT:
            emit(
                "test_budget_exceeded",
                file=path.as_posix(),
                negative_cases=count,
                limit=NEGATIVE_CASE_LIMIT,
            )
            raise ValueError("Partition independent negative cases before running")
        counts.append(count)
    return counts


def run_module(module, engine="tofu"):
    """Run the whole inventory, preserving failure and interruption semantics."""
    files = discover(module)
    counts = preflight(module, files)
    emit(
        "test_inventory",
        files=[path.as_posix() for path in files],
        negative_cases=counts,
        limit=NEGATIVE_CASE_LIMIT,
    )
    result = 0
    for number, path in enumerate(files, start=1):
        emit("test_file_start", file=path.as_posix(), index=number, total=len(files))
        code = supervise(
            [
                engine,
                f"-chdir={module}",
                "test",
                "-no-color",
                f"-filter={path.as_posix()}",
            ],
            "test",
        )
        emit("test_file_exit", file=path.as_posix(), exit_code=code)
        if code >= 128 or code == 127:
            return code
        result = result or code
    emit("test_inventory_complete", files=len(files), exit_code=result)
    return result


def main():
    """Accept paths as arguments, never interpolated shell commands."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--module", type=Path, required=True)
    args = parser.parse_args()
    try:
        return run_module(args.module.resolve())
    except (OSError, ValueError, UnicodeError) as error:
        emit("test_inventory_error", error_type=type(error).__name__)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
