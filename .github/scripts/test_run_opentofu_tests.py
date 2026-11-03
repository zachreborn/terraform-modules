"""Coverage and failure semantics for bounded native test invocations."""

import contextlib
import io
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import run_opentofu_tests as runner


class RunnerTests(unittest.TestCase):
    """Use fake supervision so these tests never need providers or credentials."""

    def test_discovery_overrides_and_fixture_exclusion(self):
        """Discover both formats and directories but not nested helper fixtures."""
        with tempfile.TemporaryDirectory() as temporary:
            module = Path(temporary)
            (module / "tests/fixtures").mkdir(parents=True)
            names = [
                "root.tftest.hcl",
                "root.tofutest.hcl",
                "tests/a.tftest.json",
                "tests/b.tofutest.json",
                "tests/c.tftest.hcl",
                "tests/c.tofutest.hcl",
                "tests/fixtures/ignored.tftest.hcl",
                "tests/ignored.py",
                "tests/.hidden.tftest.hcl",
                "tests/foo.tftest.bar.tftest.hcl",
                "tests/foo.tftest.bar.tofutest.hcl",
                "tests/distinct.tftest.bar.tftest.hcl",
                "tests/distinct.tofutest.bar.tofutest.hcl",
            ]
            for name in names:
                (module / name).touch()
            actual = [path.as_posix() for path in runner.discover(module)]
            self.assertEqual(
                actual,
                [
                    "root.tofutest.hcl",
                    "tests/a.tftest.json",
                    "tests/b.tofutest.json",
                    "tests/c.tofutest.hcl",
                    "tests/distinct.tftest.bar.tftest.hcl",
                    "tests/distinct.tofutest.bar.tofutest.hcl",
                    "tests/foo.tftest.bar.tofutest.hcl",
                ],
            )

    def test_exact_inventory_and_ordinary_failure(self):
        """Every file gets its own invocation even after an ordinary failure."""
        with tempfile.TemporaryDirectory() as temporary:
            module = Path(temporary)
            (module / "tests").mkdir()
            for name in ("a", "b", "c"):
                (module / "tests" / f"{name}.tftest.hcl").touch()
            with (
                patch.object(runner, "supervise", side_effect=[0, 7, 0]) as supervise,
                contextlib.redirect_stdout(io.StringIO()),
            ):
                code = runner.run_module(module)
            self.assertEqual(code, 7)
            prefix = ["tofu", f"-chdir={module}", "test", "-no-color"]
            expected = []
            for name in ("a", "b", "c"):
                expected.append((prefix + [f"-filter=tests/{name}.tftest.hcl"], "test"))
            self.assertEqual(
                [call.args for call in supervise.call_args_list],
                expected,
            )

    def test_interruption_stops_scheduling(self):
        """Never start later process groups after SIGINT/SIGTERM or launch error."""
        for status in (127, 130, 137, 143):
            with (
                self.subTest(status=status),
                tempfile.TemporaryDirectory() as temporary,
            ):
                module = Path(temporary)
                for name in ("a", "b"):
                    (module / f"{name}.tftest.hcl").touch()
                with (
                    patch.object(runner, "supervise", return_value=status) as supervise,
                    contextlib.redirect_stdout(io.StringIO()),
                ):
                    self.assertEqual(runner.run_module(module), status)
                self.assertEqual(supervise.call_count, 1)

    def test_preflight_rejects_whole_inventory_before_execution(self):
        """An oversized later file must not cause a partially executed green run."""
        for suffix, declaration in [
            (".tftest.hcl", "  expect_failures = [var.value]\n"),
            (".tftest.json", '"expect_failures": ["var.value"],\n'),
        ]:
            with (
                self.subTest(suffix=suffix),
                tempfile.TemporaryDirectory() as temporary,
            ):
                module = Path(temporary)
                (module / f"a{suffix}").touch()
                (module / f"z{suffix}").write_text(
                    declaration * (runner.NEGATIVE_CASE_LIMIT + 1),
                    encoding="utf-8",
                )
                with (
                    patch.object(runner, "supervise") as supervise,
                    contextlib.redirect_stdout(io.StringIO()),
                    self.assertRaisesRegex(ValueError, "Partition"),
                ):
                    runner.run_module(module)
                supervise.assert_not_called()

    def test_budget_boundary_and_zero_case_file(self):
        """The exact budget and empty native scaffolding files remain supported."""
        with tempfile.TemporaryDirectory() as temporary:
            module = Path(temporary)
            (module / "a.tftest.hcl").write_text(
                "expect_failures = [var.value]\n" * runner.NEGATIVE_CASE_LIMIT,
                encoding="utf-8",
            )
            (module / "b.tftest.hcl").touch()
            files = runner.discover(module)
            self.assertEqual(runner.preflight(module, files), [20, 0])
            with (
                patch.object(runner, "supervise", return_value=0) as supervise,
                contextlib.redirect_stdout(io.StringIO()),
            ):
                self.assertEqual(runner.run_module(module), 0)
            self.assertEqual(supervise.call_count, 2)

    def test_no_files_is_not_a_silent_success(self):
        """A broken discovery path must not skip required tests."""
        with (
            tempfile.TemporaryDirectory() as temporary,
            self.assertRaisesRegex(ValueError, "No native"),
        ):
            runner.run_module(Path(temporary))


if __name__ == "__main__":
    unittest.main()
