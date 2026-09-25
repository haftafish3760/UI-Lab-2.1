"""Bounded synthetic volume benchmark, not proof of factual or app performance.

Each stress conductor uses an explicitly fictional insulation label to exercise
unique-key volume. These are never product offerings or distributable catalogs.
Run separately from fast tests; it does not multiply every test by every item.
"""
import argparse
import copy
import ctypes
import json
import os
from pathlib import Path
import tempfile
import time

from .generate import build
from .validate import validate


def peak_memory_bytes():
    if os.name == "nt":
        from ctypes import wintypes

        class Counters(ctypes.Structure):
            _fields_ = [("cb", wintypes.DWORD), ("PageFaultCount", wintypes.DWORD)] + [
                (name, ctypes.c_size_t) for name in (
                    "PeakWorkingSetSize", "WorkingSetSize", "QuotaPeakPagedPoolUsage",
                    "QuotaPagedPoolUsage", "QuotaPeakNonPagedPoolUsage", "QuotaNonPagedPoolUsage",
                    "PagefileUsage", "PeakPagefileUsage")]

        kernel = ctypes.WinDLL("kernel32", use_last_error=True)
        psapi = ctypes.WinDLL("psapi", use_last_error=True)
        kernel.GetCurrentProcess.restype = wintypes.HANDLE
        psapi.GetProcessMemoryInfo.argtypes = [wintypes.HANDLE, ctypes.POINTER(Counters), wintypes.DWORD]
        data = Counters()
        data.cb = ctypes.sizeof(data)
        if not psapi.GetProcessMemoryInfo(kernel.GetCurrentProcess(), ctypes.byref(data), data.cb):
            raise OSError(ctypes.get_last_error(), "Cannot measure process memory")
        return data.PeakWorkingSetSize
    import resource
    import sys
    peak = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
    return peak if sys.platform == "darwin" else peak * 1024


def benchmark(count):
    if not 1000 <= count <= 200000:
        raise ValueError("Stress count must be between 1,000 and 200,000")
    root = Path(__file__).resolve().parent
    source = json.loads((root / "fixtures/candidates.json").read_text())
    conductor = next(r for r in source["candidates"] if r["family"] == "conductor")
    # Five distinct baseline identities already exist. Expected count is a
    # workload assertion only, never independent factual validation.
    for index in range(count - 5):
        row = copy.deepcopy(conductor)
        row["attributes"]["insulation"] = f"synthetic-stress-only-{index}"
        row["aliases"] = [f"synthetic stress conductor {index}"]
        source["candidates"].append(row)
    with tempfile.TemporaryDirectory(prefix="catalog-volume-") as directory:
        inputs = Path(directory) / "input.json"
        inputs.write_text(json.dumps(source, separators=(",", ":")))
        del source
        artifact = Path(directory) / "stress.sqlite"
        started = time.perf_counter()
        built = build(root / "definitions/families.json", inputs, artifact)
        generation_seconds = time.perf_counter() - started
        started = time.perf_counter()
        result = validate(artifact)
        validation_seconds = time.perf_counter() - started
        metrics = {"generation_seconds": generation_seconds, "validation_seconds": validation_seconds,
                   "artifact_bytes": artifact.stat().st_size, "input_bytes": inputs.stat().st_size,
                   "peak_process_memory_bytes": peak_memory_bytes()}
        # Initial HP development-tool budgets, not user-facing app SLAs.
        limits = {"generation_seconds": 90, "validation_seconds": 90,
                  "artifact_bytes": 256 * 1024 * 1024, "input_bytes": 128 * 1024 * 1024,
                  "peak_process_memory_bytes": 1024 * 1024 * 1024}
        breaches = [name for name, value in metrics.items() if value > limits[name]]
        passed = (not breaches and result["structural_pass"] and
                  built["canonical_count"] == count and result["coverage"]["items_examined"] == count)
        return {"scope": "synthetic generation and post-build SQLite validation only",
                "count": count, "metrics": metrics, "limits": limits, "breaches": breaches,
                "passed": passed, "release_ready": False,
                "structural_pass": result["structural_pass"],
                "errors": [x for x in result["issues"] if x["severity"] == "error"],
                "not_measured": ["app startup", "search latency", "UI", "network", "inventory", "real-product distribution"]}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--count", type=int, default=100000)
    parser.add_argument("--report", type=Path, required=True)
    args = parser.parse_args()
    result = benchmark(args.count)
    args.report.parent.mkdir(parents=True, exist_ok=True)
    with args.report.open("x", encoding="utf-8") as output:
        json.dump(result, output, indent=2)
        output.write("\n")
    print(json.dumps(result, indent=2))
    raise SystemExit(0 if result["passed"] else 1)
