"""Stream allowlisted numeric Linux metrics without logging command arguments.

Usage: python3 resource_telemetry.py --phase test -- tofu test -no-color
Samples go directly to job logs: runner shutdown can prevent artifact uploads.
SIGINT/SIGTERM are forwarded to an isolated command group with bounded cleanup.
No environment, command lines, provider state, or raw kernel logs are collected.
Memory uses KiB, disk uses bytes, and CPU uses cumulative ticks (compare adjacent
samples using ticks_per_second). Cgroup counters are optional on older hosts.
The default cadence is five seconds, plus start/end and received-signal samples.
An abrupt machine loss or SIGKILL cannot produce a final sample or identify the
signal sender; correlate the last samples with GitHub's runner diagnostics.
"""

import argparse
import json
import os
import signal
import subprocess
import time
from datetime import UTC, datetime
from pathlib import Path


def emit(event, **fields):
    """Emit one flushed, structured record; callers supply only safe fields."""
    print(
        "RESOURCE_TELEMETRY "
        + json.dumps(
            {
                "timestamp": datetime.now(UTC).isoformat(),
                "event": event,
                **fields,
            },
            sort_keys=True,
        ),
        flush=True,
    )


def numeric_fields(path, allowed):
    """Read only explicitly named numeric fields, never arbitrary file content."""
    result = {}
    try:
        for line in path.read_text(encoding="ascii").splitlines():
            parts = line.replace(":", " ").split()
            if len(parts) >= 2 and parts[0] in allowed and parts[1].isdigit():
                result[parts[0]] = int(parts[1])
    except (OSError, UnicodeError):
        pass
    return result


def cgroup_directory(proc, root):
    """Resolve this process's cgroup v2 directory, constrained to its mount."""
    try:
        for line in (proc / "self/cgroup").read_text(encoding="ascii").splitlines():
            if line.startswith("0::"):
                directory = (root / line[3:].lstrip("/")).resolve()
                if directory.is_relative_to(root.resolve()) and directory.is_dir():
                    return directory
    except (OSError, UnicodeError):
        pass
    return root


def snapshot(group, proc=Path("/proc"), cgroup=Path("/sys/fs/cgroup")):
    """Collect host and command-group counters; never read /proc/*/cmdline."""
    metrics = {
        "memory_kib": numeric_fields(
            proc / "meminfo",
            {"MemTotal", "MemAvailable", "SwapTotal", "SwapFree", "Dirty"},
        ),
        "vm": numeric_fields(proc / "vmstat", {"oom_kill", "pswpin", "pswpout"}),
        "processes": {
            "count": 0,
            "group_count": 0,
            "group_rss_pages": 0,
            "group_cpu_ticks": 0,
        },
    }
    try:
        # Cumulative host ticks, including idle and I/O wait, allow interval deltas.
        parts = (proc / "stat").read_text(encoding="ascii").splitlines()[0].split()
        if parts[0] == "cpu" and all(part.isdigit() for part in parts[1:9]):
            metrics["cpu_ticks"] = [int(part) for part in parts[1:9]]
        metrics["page_bytes"] = os.sysconf("SC_PAGE_SIZE")
        metrics["ticks_per_second"] = os.sysconf("SC_CLK_TCK")
    except (OSError, ValueError, IndexError, UnicodeError):
        pass
    try:
        disk = os.statvfs(".")
        metrics["disk_available_bytes"] = disk.f_bavail * disk.f_frsize
        metrics["disk_available_inodes"] = disk.f_favail
    except OSError:
        pass
    try:
        entries = list(proc.iterdir())
    except OSError:
        entries = []
    for entry in entries:
        if not entry.name.isdigit():
            continue
        try:
            # comm may contain spaces or parentheses; discard it entirely.
            stat = (
                (entry / "stat").read_text(encoding="ascii").rsplit(")", 1)[1].split()
            )
            metrics["processes"]["count"] += 1
            if int(stat[2]) == group:
                metrics["processes"]["group_count"] += 1
                metrics["processes"]["group_rss_pages"] += int(stat[21])
                metrics["processes"]["group_cpu_ticks"] += int(stat[11]) + int(stat[12])
        except (OSError, ValueError, IndexError, UnicodeError):
            continue
    directory = cgroup_directory(proc, cgroup)
    metrics["cgroup_memory_events"] = numeric_fields(
        directory / "memory.events",
        {"low", "high", "max", "oom", "oom_kill", "oom_group_kill"},
    )
    metrics["cgroup_cpu"] = numeric_fields(
        directory / "cpu.stat",
        {
            "usage_usec",
            "user_usec",
            "system_usec",
            "nr_periods",
            "nr_throttled",
            "throttled_usec",
        },
    )
    for name in ("memory.current", "memory.max", "pids.current", "pids.max"):
        try:
            value = (directory / name).read_text(encoding="ascii").strip()
            if value.isdigit():
                metrics[name] = int(value)
            elif value == "max":
                metrics[name] = "unlimited"
        except (OSError, UnicodeError):
            pass
    return metrics


def sample(group, phase):
    """Unavailable diagnostics must not replace a test's result."""
    try:
        emit("sample", phase=phase, **snapshot(group))
    except Exception:  # noqa: BLE001 - Diagnostics must not replace command status.
        emit("sample_unavailable", phase=phase)


def signal_group(group, signum):
    """Signal only the session created for this command, never the runner."""
    try:
        os.killpg(group, signum)
    except ProcessLookupError:
        pass


def supervise(command, phase, interval=5.0, grace=2.0):
    """Return child status, or 128+signal on interruption even if child exits 0."""
    received = []

    def interrupted(signum, _frame):
        if not received:
            received.append(signum)

    previous = {
        sig: signal.signal(sig, interrupted) for sig in (signal.SIGINT, signal.SIGTERM)
    }
    child = None
    try:
        emit("start", phase=phase)
        try:
            child = subprocess.Popen(command, start_new_session=True)
        except OSError as error:
            emit("launch_failed", phase=phase, errno=error.errno)
            return 127
        next_sample = 0.0
        deadline = None
        while True:
            now = time.monotonic()
            if received and deadline is None:
                emit("signal", phase=phase, signal=received[0])
                sample(child.pid, phase)
                signal_group(child.pid, received[0])
                deadline = now + grace
            status = child.poll()
            if status is not None:
                break
            if deadline is not None and now >= deadline:
                emit("forced_cleanup", phase=phase)
                signal_group(child.pid, signal.SIGKILL)
                status = child.wait()
                break
            if now >= next_sample:
                sample(child.pid, phase)
                next_sample = now + interval
            time.sleep(0.1)
        sample(child.pid, phase)
        code = (
            128 + received[0] if received else (128 - status if status < 0 else status)
        )
        emit("exit", phase=phase, exit_code=code)
        return code
    finally:
        if child is not None:
            # Reap remaining provider descendants, including signal-ignoring ones.
            signal_group(child.pid, signal.SIGKILL)
            child.wait()
        for sig, handler in previous.items():
            signal.signal(sig, handler)


def main():
    """Keep telemetry labels fixed; never serialize the supplied command."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--phase", required=True, choices=("version", "init", "test"))
    parser.add_argument("command", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command
    if command and command[0] == "--":
        command = command[1:]
    if not command:
        parser.error("a command is required")
    return supervise(command, args.phase)


if __name__ == "__main__":
    raise SystemExit(main())
