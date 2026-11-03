"""Offline regression tests for numeric telemetry and subprocess lifecycle."""

import contextlib
import io
import json
import os
import signal
import subprocess
import sys
import tempfile
import time
import unittest
from functools import partial
from pathlib import Path
from unittest.mock import patch

import resource_telemetry as telemetry


class MetricsTests(unittest.TestCase):
    """Use synthetic Linux files so collection is testable on any local host."""

    @unittest.skipUnless(sys.platform == "linux", "Requires live Linux procfs")
    def test_live_linux_metrics(self):
        """Confirm actual procfs collection, not just synthetic fixture parsing."""
        result = telemetry.snapshot(os.getpgrp())
        self.assertGreater(result["memory_kib"]["MemTotal"], 0)
        self.assertEqual(len(result["cpu_ticks"]), 8)
        self.assertGreater(result["processes"]["group_count"], 0)
        self.assertGreater(result["disk_available_bytes"], 0)
        self.assertGreater(result["page_bytes"], 0)
        self.assertGreater(result["ticks_per_second"], 0)

    def test_numeric_allowlist_and_command_group(self):
        """Unknown fields, process names and command lines must never escape."""
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            proc = root / "proc"
            cgroup = root / "cgroup"
            (proc / "self").mkdir(parents=True)
            (proc / "42").mkdir()
            (cgroup / "job").mkdir(parents=True)
            (proc / "self/cgroup").write_text("0::/job\n", encoding="ascii")
            (proc / "meminfo").write_text(
                "MemTotal: 100 kB\nMemAvailable: 40 kB\nprivate: excluded\n",
                encoding="ascii",
            )
            (proc / "vmstat").write_text("oom_kill 2\npswpin 3\n", encoding="ascii")
            (proc / "stat").write_text("cpu 1 2 3 4 5 6 7 8\n", encoding="ascii")
            fields = ["0"] * 22
            fields[0], fields[2] = "S", "42"
            fields[11], fields[12], fields[21] = "20", "30", "12"
            (proc / "42/stat").write_text(
                "42 (excluded ) process name) " + " ".join(fields),
                encoding="ascii",
            )
            (proc / "42/cmdline").write_text("excluded", encoding="ascii")
            events_file = cgroup / "job/memory.events"
            events_file.write_text("oom 4\noom_kill 2\nprivate 99\n", encoding="ascii")
            (cgroup / "job/memory.current").write_text("80", encoding="ascii")
            (cgroup / "job/memory.max").write_text("max", encoding="ascii")
            cpu_file = cgroup / "job/cpu.stat"
            cpu_file.write_text(
                "nr_throttled 7\nthrottled_usec 123\n",
                encoding="ascii",
            )
            result = telemetry.snapshot(42, proc, cgroup)
            self.assertEqual(
                result["memory_kib"],
                {"MemTotal": 100, "MemAvailable": 40},
            )
            self.assertEqual(result["vm"], {"oom_kill": 2, "pswpin": 3})
            self.assertEqual(result["cpu_ticks"], list(range(1, 9)))
            self.assertEqual(
                result["processes"],
                {
                    "count": 1,
                    "group_count": 1,
                    "group_rss_pages": 12,
                    "group_cpu_ticks": 50,
                },
            )
            self.assertEqual(result["cgroup_memory_events"], {"oom": 4, "oom_kill": 2})
            self.assertEqual(
                result["cgroup_cpu"],
                {"nr_throttled": 7, "throttled_usec": 123},
            )
            self.assertEqual(result["memory.current"], 80)
            self.assertEqual(result["memory.max"], "unlimited")
            self.assertNotIn("excluded", json.dumps(result))
            self.assertNotIn("private", json.dumps(result))

    def test_missing_linux_files(self):
        """Non-Linux hosts and missing optional files do not break collection."""
        with tempfile.TemporaryDirectory() as temporary:
            missing = Path(temporary) / "missing"
            result = telemetry.snapshot(42, missing, missing)
            self.assertEqual(result["memory_kib"], {})
            self.assertEqual(result["processes"]["count"], 0)
            self.assertEqual(result["cgroup_memory_events"], {})

    def test_cgroup_path_cannot_escape_mount(self):
        """A malformed membership path must not cause reads outside the mount."""
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "proc/self").mkdir(parents=True)
            (root / "proc/self/cgroup").write_text("0::/../../escape", encoding="ascii")
            self.assertEqual(
                telemetry.cgroup_directory(root / "proc", root / "cgroup"),
                root / "cgroup",
            )

    def test_collection_failure_is_nonfatal_and_redacted(self):
        """Do not print exception contents, which might include sensitive paths."""
        output = io.StringIO()
        with (
            patch.object(telemetry, "snapshot", side_effect=RuntimeError("excluded")),
            contextlib.redirect_stdout(output),
        ):
            telemetry.sample(42, "test")
        self.assertNotIn("excluded", output.getvalue())
        self.assertIn("sample_unavailable", output.getvalue())


class SupervisorTests(unittest.TestCase):
    """Exercise real isolated children without cloud services or credentials."""

    def test_monitor_error_reaps_command_and_restores_handlers(self):
        """Unexpected monitoring errors must propagate after process cleanup."""
        signals = (signal.SIGINT, signal.SIGTERM)
        previous = {sig: signal.getsignal(sig) for sig in signals}

        def failed(child, *_args, owned, failure):
            owned.append(child)
            raise failure

        for error in (RuntimeError("monitor error"), OSError("monitor error")):
            children = []
            callback = partial(failed, owned=children, failure=error)

            output = io.StringIO()
            with (
                self.subTest(error=type(error).__name__),
                patch.object(telemetry, "monitor", side_effect=callback),
                contextlib.redirect_stdout(output),
                self.assertRaisesRegex(type(error), "monitor error"),
            ):
                telemetry.supervise(
                    [sys.executable, "-c", "import time; time.sleep(60)"],
                    "test",
                )
            self.assertEqual(len(children), 1)
            self.assertIsNotNone(children[0].poll())
            self.assertNotIn("launch_failed", output.getvalue())
            for sig, handler in previous.items():
                self.assertEqual(signal.getsignal(sig), handler)

    def test_periodic_samples(self):
        """Stream samples during a command, rather than relying on final cleanup."""
        with (
            patch.object(telemetry, "sample") as sampled,
            contextlib.redirect_stdout(io.StringIO()),
        ):
            code = telemetry.supervise(
                [sys.executable, "-c", "import time; time.sleep(0.35)"],
                "test",
                interval=0.1,
            )
        self.assertEqual(code, 0)
        self.assertGreaterEqual(sampled.call_count, 3)

    def test_child_output_is_not_captured_or_rewritten(self):
        """Leave native test stdout/stderr visible and preserve nonzero exit."""
        program = """import sys
print('native-output')
print('native-error', file=sys.stderr)
sys.exit(19)
"""
        result = subprocess.run(
            [
                sys.executable,
                "-B",
                str(Path(telemetry.__file__)),
                "--phase",
                "test",
                "--",
                sys.executable,
                "-c",
                program,
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 19)
        self.assertIn("native-output", result.stdout)
        self.assertIn("native-error", result.stderr)
        records = [
            json.loads(line.removeprefix("RESOURCE_TELEMETRY "))
            for line in result.stdout.splitlines()
            if line.startswith("RESOURCE_TELEMETRY ")
        ]
        self.assertEqual(records[-1]["exit_code"], 19)
        self.assertEqual(records[-1]["phase"], "test")

    def test_success_failure_and_child_signal(self):
        """Preserve command status and restore the embedding signal handlers."""
        previous = signal.getsignal(signal.SIGTERM)
        programs = [
            ("raise SystemExit(0)", 0),
            ("raise SystemExit(23)", 23),
            ("import os,signal; os.kill(os.getpid(), signal.SIGTERM)", 143),
        ]
        for program, expected in programs:
            with (
                self.subTest(expected=expected),
                contextlib.redirect_stdout(io.StringIO()),
            ):
                self.assertEqual(
                    telemetry.supervise([sys.executable, "-c", program], "test"),
                    expected,
                )
            self.assertEqual(signal.getsignal(signal.SIGTERM), previous)

    def test_telemetry_failure_does_not_mask_command_failure(self):
        """An unavailable sample must not turn a failing command green."""
        with (
            patch.object(telemetry, "snapshot", side_effect=OSError("excluded")),
            contextlib.redirect_stdout(io.StringIO()),
        ):
            self.assertEqual(
                telemetry.supervise(
                    [sys.executable, "-c", "raise SystemExit(17)"],
                    "init",
                ),
                17,
            )

    def test_missing_command(self):
        """A launch failure is explicit, nonzero and excludes the command path."""
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            result = telemetry.supervise(["/nonexistent/excluded"], "test")
        self.assertEqual(result, 127)
        self.assertNotIn("excluded", output.getvalue())

    def test_interrupts_and_descendant_cleanup(self):
        """Forward both signals, resist false success, and stop stubborn children."""
        for sig, behavior in [
            (signal.SIGINT, "signal.SIG_DFL"),
            (signal.SIGTERM, "lambda *_: sys.exit(0)"),
            (signal.SIGTERM, "signal.SIG_IGN"),
        ]:
            with self.subTest(signal=sig, behavior=behavior):
                self.check_interrupt(sig, behavior)

    def check_interrupt(self, signum, behavior):
        """Wait for child readiness before signaling only the supervisor."""
        with (
            tempfile.TemporaryDirectory() as temporary,
            contextlib.ExitStack() as processes,
        ):
            ready = Path(temporary) / "ready"
            program = (
                "import os,signal,subprocess,sys,time; from pathlib import Path; "
                f"signal.signal(signal.SIGINT, {behavior}); "
                f"signal.signal(signal.SIGTERM, {behavior}); "
                "child=subprocess.Popen([sys.executable, '-c', "
                "'import signal,time; signal.signal(signal.SIGTERM, signal.SIG_IGN); "
                "time.sleep(60)']); "
                f"Path({str(ready)!r}).write_text(str(child.pid)); "
                "time.sleep(60)"
            )
            process = processes.enter_context(
                subprocess.Popen(
                    [
                        sys.executable,
                        "-B",
                        str(Path(telemetry.__file__)),
                        "--phase",
                        "test",
                        "--",
                        sys.executable,
                        "-c",
                        program,
                    ],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                    text=True,
                )
            )
            descendant = None
            try:
                deadline = time.monotonic() + 10
                while not ready.exists() and time.monotonic() < deadline:
                    time.sleep(0.02)
                self.assertTrue(
                    ready.exists(),
                    "Child must be ready before interruption",
                )
                descendant = int(ready.read_text(encoding="ascii"))
                process.send_signal(signum)
                stdout, stderr = process.communicate(timeout=8)
                self.assertEqual(process.returncode, 128 + signum, stderr)
                self.assertIn('"event": "signal"', stdout)
                self.assertIn(f'"exit_code": {128 + signum}', stdout)
                self.assertNotIn(str(ready), stdout)
                # The command source/arguments are not included in telemetry.
                self.assertNotIn("subprocess.Popen", stdout)
                if sys.platform == "linux":
                    try:
                        stat_file = Path(f"/proc/{descendant}/stat")
                        contents = stat_file.read_text(encoding="ascii")
                        state = contents.rsplit(")", 1)[1].split()[0]
                    except FileNotFoundError:
                        state = ""
                else:
                    state = subprocess.run(
                        ["ps", "-o", "stat=", "-p", str(descendant)],
                        capture_output=True,
                        text=True,
                        check=False,
                    ).stdout.strip()
                self.assertTrue(
                    not state or state.startswith("Z"),
                    "Descendant survived",
                )
            finally:
                if process.poll() is None:
                    process.kill()
                    process.communicate()
                if descendant is not None:
                    try:
                        os.kill(descendant, signal.SIGKILL)
                    except ProcessLookupError:
                        pass


if __name__ == "__main__":
    unittest.main()
