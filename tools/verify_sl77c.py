#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CI_MODE = "--ci" in sys.argv

EXPECTED = {
    ".github/workflows/android_debug.yml",
    "lib/features/live_alert/live_alert_rescue_screen.dart",
    "test/live_alert_rescue_used_tools_test.dart",
    "tools/verify_sl77c.py",
}

def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)

def read(path: str) -> str:
    target = ROOT / path
    if not target.is_file():
        fail(f"Missing {path}")
    return target.read_text(encoding="utf-8")

def require(text: str, token: str, label: str) -> None:
    if token not in text:
        fail(f"Missing {label}: {token}")

if not CI_MODE:
    result = subprocess.run(
        ["git", "diff", "--cached", "--name-only"],
        cwd=ROOT, text=True, capture_output=True, check=True,
    )
    changed = {line.strip() for line in result.stdout.splitlines() if line.strip()}
    if changed != EXPECTED:
        fail(
            "Staged scope mismatch. "
            f"Expected {sorted(EXPECTED)}, found {sorted(changed)}"
        )
    print("PASS: SL-77C staged-file scope is exact.")
else:
    print("PASS: CI mode skips staged-file scope.")

live = read("lib/features/live_alert/live_alert_rescue_screen.dart")
tests = read("test/live_alert_rescue_used_tools_test.dart")
workflow = read(".github/workflows/android_debug.yml")

for token, label in {
    "bool get _hasUsedRescueTools =>": "used-tools state getter",
    "_usedWait || _usedReasons || _usedSupport": "exact used-tool sources",
    "You've already used": "used-tools heading",
    "10-minute pause started": "pause status",
    "Reasons reviewed": "reasons status",
    "Support contacted": "support status",
    "if (_hasUsedRescueTools)": "conditional used-tools card",
}.items():
    require(live, token, label)

if "_leavingConfirmed ||" in live or "|| _leavingConfirmed" in live:
    fail("Leaving-now state must not count as one of SL-77C's used rescue tools.")

for token, label in {
    "_usedWait = true;": "pause immediate state",
    "_usedReasons = true;": "reasons immediate state",
    "_usedSupport = true;": "support-used state",
}.items():
    require(live, token, label)

for token in [
    "used-tools section appears and updates as rescue tools are used",
    "10-minute pause started",
    "Reasons reviewed",
    "Support contacted",
]:
    require(tests, token, "SL-77C widget regression coverage")

require(
    workflow,
    "flutter test test/live_alert_rescue_used_tools_test.dart",
    "SL-77C Flutter test gate",
)
require(
    workflow,
    "python tools/verify_sl77c.py --ci",
    "SL-77C verifier gate",
)

print("PASS: used-tools card is hidden until a rescue tool is used.")
print("PASS: pause, reasons, and support each surface immediately after use.")
print("PASS: leaving-now state is intentionally separate from used-tool history.")
print("PASS: SL-77C widget and source-contract CI gates are wired.")
print("SL-77C VERIFICATION PASSED")
